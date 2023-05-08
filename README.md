# Magic tools

## MagicSeries

MagicSeries is an ERC1155 to manage things.

For example, if Twitter wants to give operators a working hours badge. It can create a new series, calling:

```javascript
await magicSeries.createNewSeries(
  "Twitter Working Hours Badge",
  "A series to rewards decentralized Twitter operators",
  "https://twitter.com/Twitter/photo",
  false // not burnable by the creator
);
```

and get the new series ID calling

```javascript
await magicSeries.seriesByCreator("0x1234567890123456789012345678901234567890");
```

Then, Twitter can mint new editions for some operators, calling something like:

```javascript
const seriesId = 18;
const recipients = [
  "0x1234567890123456789012345678901234560000",
  "0x1234567890123456789012345678901234560001",
  "0x1234567890123456789012345678901234560002",
];
const amounts = [50, 23, 12];
await magicSeries.mint(seriesId, recipients, amounts);
```

The metadata of any series can be retrieved calling:

```javascript
await magicSeries.metadata(seriesId);
```

## Can I use it?

Yes, The contract has been deployed at:

_coming soon_

## Copyright

(2023), Francesco Sullo <francesco@sullo.co>, Cruna

## License

MIT
