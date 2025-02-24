defmodule EthereumJSONRPC.AmazeToken.Verifier do
  @moduledoc """
  """
  require Logger

  import EthereumJSONRPC, only: [quantity_to_integer: 1, integer_to_quantity: 1, request: 1]

  alias EthereumJSONRPC

  @type elixir :: %{
          String.t() => EthereumJSONRPC.address() | EthereumJSONRPC.hash() | String.t() | non_neg_integer() | nil
        }

  @typedoc """
   * `"blockHash"` - `t:EthereumJSONRPC.hash/0` of the block this transaction is in.  `nil` when transaction is
     pending.
   * `"blockNumber"` - `t:EthereumJSONRPC.quantity/0` for the block number this transaction is in.  `nil` when
     transaction is pending.
   * `"chainId"` - the chain on which the transaction exists.
   * `"condition"` - UNKNOWN
   * `"creates"` - `t:EthereumJSONRPC.address/0` of the created contract, if the transaction creates a contract.
   * `"from"` - `t:EthereumJSONRPC.address/0` of the sender.
   * `"gas"` - `t:EthereumJSONRPC.quantity/0` of gas provided by the sender.  This is the max gas that may be used.
     `gas * gasPrice` is the max fee in wei that the sender is willing to pay for the transaction to be executed.
   * `"gasPrice"` - `t:EthereumJSONRPC.quantity/0` of wei to pay per unit of gas used.
   * `"hash"` - `t:EthereumJSONRPC.hash/0` of the transaction
   * `"input"` - `t:EthereumJSONRPC.data/0` sent along with the transaction, such as input to the contract.
   * `"nonce"` - `t:EthereumJSONRPC.quantity/0` of transactions made by the sender prior to this one.
   * `"publicKey"` - `t:EthereumJSONRPC.hash/0` of the public key of the signer.
   * `"r"` - `t:EthereumJSONRPC.quantity/0` for the R field of the signature.
   * `"raw"` - Raw transaction `t:EthereumJSONRPC.data/0`
   * `"standardV"` - `t:EthereumJSONRPC.quantity/0` for the standardized V (`0` or `1`) field of the signature.
   * `"to"` - `t:EthereumJSONRPC.address/0` of the receiver.  `nil` when it is a contract creation transaction.
   * `"transactionIndex"` - `t:EthereumJSONRPC.quantity/0` for the index of the transaction in the block.  `nil` when
     transaction is pending.
   * `"v"` - `t:EthereumJSONRPC.quantity/0` for the V field of the signature.
   * `"value"` - `t:EthereumJSONRPC.quantity/0` of wei transferred.
   * `"maxPriorityFeePerGas"` - `t:EthereumJSONRPC.quantity/0` of wei to denote max priority fee per unit of gas used. Introduced in [EIP-1559](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md)
   * `"maxFeePerGas"` - `t:EthereumJSONRPC.quantity/0` of wei to denote max fee per unit of gas used. Introduced in [EIP-1559](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md)
   * `"type"` - `t:EthereumJSONRPC.quantity/0` denotes transaction type. Introduced in [EIP-1559](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md)
  """
  @type t :: %{
          String.t() =>
            EthereumJSONRPC.address() | EthereumJSONRPC.hash() | EthereumJSONRPC.quantity() | String.t() | nil
        }

  @type params :: %{
          address_hash: EthereumJSONRPC.address(),
#          address_hash: String.t(),
          block_hash: EthereumJSONRPC.hash(),
          block_number: non_neg_integer(),
          publicKey: String.t()
        }

  @doc """
  Geth `elixir` can be converted to `params`.  Geth does not supply `"publicKey"` or `"standardV"`, unlike Parity.

      iex> EthereumJSONRPC.Transaction.elixir_to_params(
      ...>   %{
      ...>     "blockHash" => "0x4e3a3754410177e6937ef1f84bba68ea139e8d1a2258c5f85db9f1cd715a1bdd",
      ...>     "blockNumber" => 46147,
      ...>     "from" => "0xa1e4380a3b1f749673e270229993ee55f35663b4",
      ...>     "gas" => 21000,
      ...>     "gasPrice" => 50000000000000,
      ...>     "hash" => "0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060",
      ...>     "input" => "0x",
      ...>     "nonce" => 0,
      ...>     "r" => 61965845294689009770156372156374760022787886965323743865986648153755601564112,
      ...>     "s" => 31606574786494953692291101914709926755545765281581808821704454381804773090106,
      ...>     "to" => "0x5df9b87991262f6ba471f09758cde1c0fc1de734",
      ...>     "transactionIndex" => 0,
      ...>     "v" => 28,
      ...>     "value" => 31337
      ...>   }
      ...> )
      %{
        block_hash: "0x4e3a3754410177e6937ef1f84bba68ea139e8d1a2258c5f85db9f1cd715a1bdd",
        block_number: 46147,
        from_address_hash: "0xa1e4380a3b1f749673e270229993ee55f35663b4",
        gas: 21000,
        gas_price: 50000000000000,
        hash: "0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060",
        index: 0,
        input: "0x",
        nonce: 0,
        r: 61965845294689009770156372156374760022787886965323743865986648153755601564112,
        s: 31606574786494953692291101914709926755545765281581808821704454381804773090106,
        to_address_hash: "0x5df9b87991262f6ba471f09758cde1c0fc1de734",
        v: 28,
        value: 31337,
        transaction_index: 0
      }

  """
  @spec elixir_to_params(elixir) :: params

  def elixir_to_params(
        %{
          "Address" => address_hash,
          "block_hash" => block_hash,
          "block_number" => block_number,
          "PublicKey" => publicKey
        } = verifier
      ) do
    result = %{
      address_hash: address_hash,
      block_hash: block_hash,
      block_number: block_number,
      public_key: publicKey
    }
    result
  end




  @doc """
  Decodes the stringly typed numerical fields to `t:non_neg_integer/0`.

  Pending transactions have a `nil` `"blockHash"`, `"blockNumber"`, and `"transactionIndex"` because those fields are
  related to the block the transaction is collated in.

    iex> EthereumJSONRPC.Transaction.to_elixir(
    ...>   %{
    ...>     "blockHash" => nil,
    ...>     "blockNumber" => nil,
    ...>     "chainId" => "0x4d",
    ...>     "condition" => nil,
    ...>     "creates" => nil,
    ...>     "from" => "0x40aa34fb35ef0804a41c2b4be7d3e3d65c7f6d5c",
    ...>     "gas" => "0xcf08",
    ...>     "gasPrice" => "0x0",
    ...>     "hash" => "0x6b80a90c958fb5791a070929379ed6eb7a33ecdf9f9cafcada2f6803b3f25ec3",
    ...>     "input" => "0x",
    ...>     "nonce" => "0x77",
    ...>     "publicKey" => "0xd0bf6fb4ce4ada1ddfb754b98cd89dc61c3ff143a260cf1712517af2af602b699aab554a2532051e5ba205eb41068c3423f23acde87313211750a8cbf862170e",
    ...>     "r" => "0x3cfc2a34c2e4e09913934a5ade1055206e39b1e34fabcfcc820f6f70c740944c",
    ...>     "raw" => "0xf868778082cf08948e854802d695269a6f1f3fcabb2111d2f5a0e6f9880de0b6b3a76400008081bea03cfc2a34c2e4e09913934a5ade1055206e39b1e34fabcfcc820f6f70c740944ca014cf6f15b5855f9b68eb58c95f76603a54b2ca612f921bb8d424de11bf085390",
    ...>     "s" => "0x14cf6f15b5855f9b68eb58c95f76603a54b2ca612f921bb8d424de11bf085390",
    ...>     "standardV" => "0x1",
    ...>     "to" => "0x8e854802d695269a6f1f3fcabb2111d2f5a0e6f9",
    ...>     "transactionIndex" => nil,
    ...>     "v" => "0xbe",
    ...>     "value" => "0xde0b6b3a7640000"
    ...>   }
    ...> )
    %{
      "blockHash" => nil,
      "blockNumber" => nil,
      "chainId" => 77,
      "condition" => nil,
      "creates" => nil,
      "from" => "0x40aa34fb35ef0804a41c2b4be7d3e3d65c7f6d5c",
      "gas" => 53000,
      "gasPrice" => 0,
      "hash" => "0x6b80a90c958fb5791a070929379ed6eb7a33ecdf9f9cafcada2f6803b3f25ec3",
      "input" => "0x",
      "nonce" => 119,
      "publicKey" => "0xd0bf6fb4ce4ada1ddfb754b98cd89dc61c3ff143a260cf1712517af2af602b699aab554a2532051e5ba205eb41068c3423f23acde87313211750a8cbf862170e",
      "r" => 27584307671108667307432650922507113611469948945973084068788107666229588694092,
      "raw" => "0xf868778082cf08948e854802d695269a6f1f3fcabb2111d2f5a0e6f9880de0b6b3a76400008081bea03cfc2a34c2e4e09913934a5ade1055206e39b1e34fabcfcc820f6f70c740944ca014cf6f15b5855f9b68eb58c95f76603a54b2ca612f921bb8d424de11bf085390",
      "s" => 9412760993194218539611435541875082818858943210434840876051960418568625476496,
      "standardV" => 1,
      "to" => "0x8e854802d695269a6f1f3fcabb2111d2f5a0e6f9",
      "transactionIndex" => nil,
      "v" => 190,
      "value" => 1000000000000000000
    }

  """
  def to_elixir(verifier) when is_map(verifier) do
    Enum.into(verifier, %{}, &entry_to_elixir/1)
  end

  defp entry_to_elixir({key, value})
       when key in ~w(Address PublicKey),
       do: {key, value}


end
