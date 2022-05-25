# AAVE Governance Forge Template

A template for creating AAVE governance Proposal payload contracts.

## Setup

- Rename `.env.example` to `.env`. Add a valid URL for an Ethereum JSON-RPC client for the `FORK_URL` variable
- Follow the [foundry installation instructions](https://github.com/gakonst/foundry#installation)

```
$ forge init --template https://github.com/llama-community/aave-governance-forge-template my-repo
$ cd my-repo
$ forge install
```

If the compiler can't find stdlib.sol:
1) copy this [gist](https://gist.github.com/defijesus/125b338f31a18359aa9114ba2df37add)
2) create a new file with the contents @ `./lib/forge-std/src/stdlib.sol`

## Tests

```
$ make test # run tests without traces
$ make trace # run tests with traces
```

## Acknowledgements
* [Steven Valeri](https://github.com/stevenvaleri/): Re-wrote AAVE's governance process tests in solidity.
