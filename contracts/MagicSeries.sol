// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// MagicSeries allows anyone to create a series, defining name, description and image
// for the series. Then, the series creator, can distribute new tokens for that series to
// whoever s/he/they wants.

contract MagicSeries is ERC1155 {
  using Address for address;
  using Strings for uint256;

  event SeriesCreated(
    uint256 indexed seriesId,
    address indexed creator,
    string name,
    string description,
    string image,
    address minter,
    address burner
  );

  event SeriesMinterUpdated(uint256 indexed seriesId, address indexed minter);

  event SeriesBurnerUpdated(uint256 indexed seriesId, address indexed burner);

  event SeriesMetadataUpdated(uint256 indexed seriesId, string name, string description, string image);

  error NotTheSeriesCreator();
  error NotTheSeriesMinter();
  error NotTheSeriesBurner();
  error InconsistentArrays();
  error SeriesNotFound();
  error MintingHasEnded();
  error MinterAlreadySet();
  error NotBurnable();
  error BurnerAlreadySet();

  uint256 private _nextSeriesId;
  string public version = "0.1.0";

  // this is relatively expensive, but its cost will reduce abuses
  struct Series {
    uint256 createdAtBlock;
    address creator;
    string name;
    string description;
    string image;
    address minter;
    address burner;
  }

  mapping(uint256 => Series) internal _series;
  mapping(address => uint256[]) private _seriesByCreator;

  modifier onlySeriesCreator(uint256 seriesId) {
    if (_msgSender() != _series[seriesId].creator) revert NotTheSeriesCreator();
    _;
  }

  modifier onlySeriesMinter(uint256 seriesId) {
    if (address(0) == _series[seriesId].minter) revert MintingHasEnded();
    if (_msgSender() != _series[seriesId].minter) revert NotTheSeriesMinter();
    _;
  }

  modifier onlySeriesBurner(uint256 seriesId) {
    if (address(0) == _series[seriesId].burner) revert NotBurnable();
    if (_msgSender() != _series[seriesId].burner) revert NotTheSeriesBurner();
    _;
  }

  modifier seriesExists(uint256 seriesId) {
    if (_series[seriesId].creator == address(0)) revert SeriesNotFound();
    _;
  }

  // solhint-disable-next-line
  constructor() ERC1155("") {
    _setURI(string(abi.encodePacked("https://meta.cruna.cc/magic-series/", block.chainid.toString(), "/{id}")));
  }

  /*
    @dev Creates a new series
    @param name The name of the series.
    @param description The description of the series
    @param image The image of the series
    @param minter The address that can mint tokens of the series
     The minter would ideally be a smart contract, but it is not mandatory.
     If minter is address(0), the owner of the series is the minter.
    @param burner The address that can burn tokens of the series
     The burner should be a smart contract, but it is not mandatory.
     The idea is that, for example, the tokens in the series can be
     burned to swap there with other tokens.
     If the burner is address(0), the series is not burnable.
     For clarity, if the burner is not set at creation, it cannot be set later.
  */
  function createSeries(
    string memory name,
    string memory description,
    string memory image,
    address minter,
    address burner
  ) public {
    if (minter == address(0)) minter = _msgSender();
    _series[++_nextSeriesId] = Series({
      createdAtBlock: block.number,
      creator: _msgSender(),
      name: name,
      description: description,
      image: image,
      minter: minter,
      burner: burner
    });
    _seriesByCreator[_msgSender()].push(_nextSeriesId);
    emit SeriesCreated(_nextSeriesId, _msgSender(), name, description, image, minter, burner);
  }

  /*
    @dev Update image and burner address of a series
    @param seriesId The id of the series
    @param name The name of the series, if not empty, it will be applied
    @param description The description of the series, if not empty, it will be applied
    @param image The image of the series, if not empty, it will be applied
  */
  function updateSeriesMetadata(
    uint256 seriesId,
    string memory name,
    string memory description,
    string memory image
  ) external onlySeriesCreator(seriesId) {
    if (bytes(name).length != 0) _series[seriesId].name = name;
    if (bytes(description).length != 0) _series[seriesId].description = description;
    if (bytes(image).length != 0) _series[seriesId].image = image;
    emit SeriesMetadataUpdated(seriesId, name, description, image);
  }

  /*
    @dev Update the minter address of a series
    @param seriesId The id of the series
    @param minter The address that can mint tokens of the series.
      If the new minter is address(0), the series won't be mintable anymore.
  */
  function updateSeriesMinter(uint256 seriesId, address minter) external onlySeriesCreator(seriesId) {
    if (_series[seriesId].minter == address(0)) revert MintingHasEnded();
    if (_series[seriesId].minter == minter) revert MinterAlreadySet();
    _series[seriesId].minter = minter;
    emit SeriesMinterUpdated(seriesId, minter);
  }

  /*
    @dev Update the burner address of a series
    @param seriesId The id of the series
    @param burner The address that can burn tokens of the series.
      It will revert if the series was not burnable in the first instance.
      If the new address is address(0), the series will not be burnable anymore.
  */
  function updateSeriesBurner(uint256 seriesId, address burner) external onlySeriesCreator(seriesId) {
    if (_series[seriesId].burner == address(0)) revert NotBurnable();
    if (_series[seriesId].burner == burner) revert BurnerAlreadySet();
    _series[seriesId].burner = burner;
    emit SeriesBurnerUpdated(seriesId, burner);
  }

  /*
    @dev Private function that convert a uint to a uint[]
    @param elem The single element
    @return An array containing the single element
  */
  function _arr(uint256 elem) private pure returns (uint256[] memory) {
    uint256[] memory arr = new uint256[](1);
    arr[0] = elem;
    return arr;
  }

  /*
    @dev Mint a token of a series
    @param seriesId The id of the series
    @param recipients An array of addresses that will receive the token
    @param amounts An array of amounts of tokens to mint
  */
  function mint(
    uint256 seriesId,
    address[] memory recipients,
    uint256[] memory amounts
  ) public onlySeriesMinter(seriesId) {
    if (recipients.length != amounts.length) revert InconsistentArrays();
    for (uint256 i = 0; i < recipients.length; i++) {
      _mintBatch(recipients[i], _arr(seriesId), _arr(amounts[i]), "");
    }
  }

  /*
    @dev Burn tokens of a series
    @param seriesId The id of the series
    @param recipients An array of addresses that will receive the token
    @param amounts An array of amounts of tokens to burn
  */
  function burn(
    uint256 seriesId,
    address[] memory recipients,
    uint256[] memory amounts
  ) public onlySeriesBurner(seriesId) {
    if (recipients.length != amounts.length) revert InconsistentArrays();
    for (uint256 i = 0; i < recipients.length; i++) {
      _burn(recipients[i], seriesId, amounts[i]);
    }
  }

  /*
    @dev Get the series ids created by an address
    @param creator The address of the creator
    @return An array of series ids
  */
  function seriesByCreator(address creator) public view returns (uint256[] memory) {
    return _seriesByCreator[creator];
  }

  /*
    @dev Get the series ids created by an address with their names
    @param creator The address of the creator
    @return An array of series ids with their names
  */
  function seriesByCreatorWithNames(address creator) public view returns (string[] memory) {
    uint256[] memory seriesIds = _seriesByCreator[creator];
    string[] memory seriesNames = new string[](seriesIds.length);
    for (uint256 i = 0; i < seriesIds.length; i++) {
      uint256 id = seriesIds[i];
      seriesNames[i] = string(abi.encodePacked(id.toString(), " ", _series[id].name));
    }
    return seriesNames;
  }

  /*
    @dev Get the series created by an address
    @param creator The address of the creator
    @return An array of Series structures
  */
  function series(uint256 seriesId) public view seriesExists(seriesId) returns (Series memory) {
    return _series[seriesId];
  }

  /*
    @dev Converts the a series to a JSON string
    @param seriesId The id of the series
    @return A JSON string representing the series
  */
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
          '","creator":"',
          uint256(uint160(_series[seriesId].creator)).toHexString(),
          // solhint-disable-next-line quotes
          '","minter":"',
          uint256(uint160(_series[seriesId].minter)).toHexString(),
          // solhint-disable-next-line quotes
          '","burner":"',
          uint256(uint160(_series[seriesId].burner)).toHexString(),
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
}
