defmodule BlockScoutWeb.BlockMinerRewardView do
  use BlockScoutWeb, :view

  alias Explorer.Chain.Block.MinnerReward
  import BlockScoutWeb.Gettext, only: [gettext: 1]

  def block_not_found_message({:ok, true}) do
    gettext("Easy Cowboy! This block does not exist yet!")
  end

  def block_not_found_message({:ok, false}) do
    gettext("This block has not been processed yet.")
  end

  def block_not_found_message({:error, :hash}) do
    gettext("Block not found, please try again later.")
  end

  def balance(%MinnerReward{amount: nil}), do: ""

  def balance(%MinnerReward{amount: balance}) do
    format_wei_value(balance, :ether)
  end

end
