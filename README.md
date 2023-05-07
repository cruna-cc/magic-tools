# Magic tools

## MagicBin

MagicBin is an ERC1155 to manage things. 

For example, if Twitter wants to give operators a working hours badge. It can create a new series, calling:

```javascript
await magicBin.createNewSeries(
  "Twitter Working Hours Badge",
  "A series to rewards decentralized Twitter operators",
  "https://twitter.com/Twitter/photo"
)
```
and get the new series ID calling
```javascript
await magicBin.seriesByCreator("0x1234567890123456789012345678901234567890")
```

Then, Twitter can mint new editions for some operators, calling something like:
```javascript
const seriesId = 18;
const recipients = [
    "0x1234567890123456789012345678901234560000",
    "0x1234567890123456789012345678901234560001",
    "0x1234567890123456789012345678901234560002"
];
const amounts = [ 50, 23, 12 ];
await magicBin.mint(seriesId, recipients, amounts);
```

The metadata of any series can be retrieved calling:
```javascript
await magicBin.metadata(seriesId);
```

## Can I use it?

Yes, The contract has been deployed at: 

_coming soon_

## Copyright

(2023), Francesco Sullo <francesco@sullo.co>, Cruna

## License

MIT
