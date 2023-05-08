// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// MagicSeries allows anyone to create a series, defining name, description and image
// for the series. Then, the series creator, can distribute new tokens for that series to
// whoever s/he/they wants.

contract MagicSeries is ERC1155, Ownable {
  using Address for address;
  using Strings for uint256;

  error NotTheSeriesCreator();
  error InconsistentArrays();
  error SeriesNotFound();
  error NotBurnable();

  uint256 private _nextSeriesId;

  // this is relatively expensive, but its cost will reduce abuses
  struct Series {
    uint256 createdAtBlock;
    address creator;
    string name;
    string description;
    string image;
    bool burnable;
  }

  mapping(uint256 => Series) internal _series;
  mapping(address => uint256[]) private _seriesByCreator;

  modifier onlySeriesCreator(uint256 seriesId) {
    if (_msgSender() != _series[seriesId].creator) revert NotTheSeriesCreator();
    _;
  }

  modifier onlyBurnable(uint256 seriesId) {
    if (!_series[seriesId].burnable) revert NotBurnable();
    _;
  }

  modifier seriesExists(uint256 seriesId) {
    if (_series[seriesId].creator == address(0)) revert SeriesNotFound();
    _;
  }

  // solhint-disable-next-line
  constructor() ERC1155("") {
    _setURI(string(abi.encodePacked("https://meta.cruna.cc/magic-bin/", block.chainid.toString(), "/{id}")));
  }

  function createSeries(
    string memory name,
    string memory description,
    string memory image,
    bool burnable
  ) public {
    _series[++_nextSeriesId] = Series({
      createdAtBlock: block.number,
      creator: _msgSender(),
      name: name,
      description: description,
      image: image,
      burnable: burnable
    });
    _seriesByCreator[_msgSender()].push(_nextSeriesId);
  }

  function _arr(uint256 elem) internal pure returns (uint256[] memory) {
    uint256[] memory arr = new uint256[](1);
    arr[0] = elem;
    return arr;
  }

  function mint(
    uint256 seriesId,
    address[] memory recipients,
    uint256[] memory amounts
  ) public onlySeriesCreator(seriesId) {
    if (recipients.length != amounts.length) revert InconsistentArrays();
    for (uint256 i = 0; i < recipients.length; i++) {
      _mintBatch(recipients[i], _arr(seriesId), _arr(amounts[i]), "");
    }
  }

  function burn(
    uint256 seriesId,
    address[] memory recipients,
    uint256[] memory amounts
  ) public onlySeriesCreator(seriesId) onlyBurnable(seriesId) {
    if (recipients.length != amounts.length) revert InconsistentArrays();
    for (uint256 i = 0; i < recipients.length; i++) {
      _burn(recipients[i], seriesId, amounts[i]);
    }
  }

  function seriesByCreator(address creator) public view returns (uint256[] memory) {
    return _seriesByCreator[creator];
  }

  function seriesByCreatorWithNames(address creator) public view returns (string[] memory) {
    uint256[] memory seriesIds = _seriesByCreator[creator];
    string[] memory seriesNames = new string[](seriesIds.length);
    for (uint256 i = 0; i < seriesIds.length; i++) {
      uint256 id = seriesIds[i];
      seriesNames[i] = string(abi.encodePacked(id.toString(), " ", _series[id].name));
    }
    return seriesNames;
  }

  function series(uint256 seriesId) public view seriesExists(seriesId) returns (Series memory) {
    return _series[seriesId];
  }

  function metadata(uint256 seriesId) public view seriesExists(seriesId) returns (string memory) {
    return
      string(
        abi.encodePacked(
          // solhint-disable-next-line quotes
          '{"name":"',
          _series[seriesId].name,
          // solhint-disable-next-line quotes
          '","description":"',
          _series[seriesId].description,
          // solhint-disable-next-line quotes
          '","image":"',
          _series[seriesId].image,
          // solhint-disable-next-line quotes
          '","burnable":',
          _series[seriesId].burnable ? "true" : "false",
          // solhint-disable-next-line quotes
          ',"creator":"',
          _addressToString(_series[seriesId].creator),
          // solhint-disable-next-line quotes
          '","seriesId":',
          seriesId.toString(),
          // solhint-disable-next-line quotes
          ',"createdAtBlock":',
          _series[seriesId].createdAtBlock.toString(),
          "}"
        )
      );
  }

  function _addressToString(address _addr) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }
}
