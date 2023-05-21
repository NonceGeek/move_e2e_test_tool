defmodule MoveE2ETestToolTest do
  require Logger
  use ExUnit.Case

  test "move call" do
    cmd = %{
      "args" => [
        "0x1e52e73d3ee211cc90e81d495ce2890dd2e2cddfe60856f8689c174fd304bf85",
        "0xfc7319ac27c323e57bd7f4875b79bc66d7b0dc12eaf7c45d0bef6a17a1db2dd3"
      ],
      "cli" => "sui_client",
      "cmd" => "call",
      "function" => ["buy_bread"],
      "gas-budget" => ["30000"],
      "module" => ["sandwich"],
      "package" => ["0x2a1eb129432e6ce76e8aac65ba1e672ad9c5ceb203c3483ee2628506db46ea7c"]
    }

    {:ok, client} = Web3MoveEx.Sui.RPC.connect(:devnet)
    acct = Web3MoveEx.Sui.Account.from("AKpjfApmHx8FbjrRRSrUlF6ITigjP8NMS1ip4JdqPp5g")
    {:ok, agent} = Agent.start(fn -> %{client: client, acct: acct} end)
    res = MoveE2ETestTool.CliParser.cmd(agent, cmd)
    assert res == :ok
  end

  test "runtime compile" do
    Code.eval_string("defmodule A do\ndef a do\n1\nend\nend")
    assert 1 = A.a()
  end

  test "generate code" do
    assert 1 = MoveE2ETestTool.CliParser.run("a=1\nassert a=1\n1")
    new_address = "
        LOG=DEBUG
        sui client new-address
        expect = %{cli: :sui_client, cmd: :new_address}
        assert expect = cmd
        {:ok, %Web3MoveEx.Sui.Account{
         priv_key_base64: _,
        }} = res
        IO.inspect(res)
        :ok
        "
    assert :ok == MoveE2ETestTool.CliParser.run(new_address)
  end

  test "parse script" do
    assert [
             %{cli: :sui_client, args: ["secp256k1"], cmd: :"new-address"},
             %{cli: :comment, line: "    # 导入一个已有地址"},
             %{cli: :comment, line: "    # 执行 ex 特有的 script"},
             %{
               args: ["AKpjfApmHx8FbjrRRSrUlF6ITigjP8NMS1ip4JdqPp5g"],
               cli: :sui_client,
               cmd: :"import-address"
             },
             %{cli: :comment, line: "    # ex_script: set contract [contract_addr_str]"},
             %{cli: :comment, line: "    # 查看已有地址的 gas 费用"},
             %{cli: :sui_client, cmd: :gas},
             %{cli: :comment, line: "    # buy_bread"},
             %{
               args: ["args1", "args2"],
               cli: :sui_client,
               cmd: :call,
               function: ["buy_bread"],
               gas: ["gas_obj"],
               "gas-budget": ["30000"],
               module: ["sandwich"],
               package: ["0x08204ed92afcfdf9d0f6727a2c7d40db93a059d8"]
             },
             %{cli: :comment, line: "    # check if there is a bread"},
             %{cli: :comment, line: "    # // TODO"},
             %{cli: :comment, line: "    # buy_ham"},
             %{
               args: ["args1", "args2"],
               cli: :sui_client,
               cmd: :call,
               function: ["buy_ham"],
               gas: ["gas_obj"],
               "gas-budget": ["30000"],
               module: ["sandwich"],
               package: ["0x08204ed92afcfdf9d0f6727a2c7d40db93a059d8"]
             },
             %{cli: :comment, line: "    # check if there is a ham"},
             %{cli: :code, line: "    a=a"},
             %{cli: :code, line: "    #"}
           ] = MoveE2ETestTool.SuiCliParser.parse_script_to_clis(script())
  end

  test "sui client import_address" do
    assert %{
             cli: :sui_client,
             cmd: :"import-address",
             args: [
               "AMSs6F3/uRvzqCXXinpSQLpn+d5wH8lWlN2w1a2T7XCW",
               "--profile",
               "leeduckgo"
             ]
           } =
             MoveE2ETestTool.SuiCliParser.parse_cmd(
               "sui client import-address AMSs6F3/uRvzqCXXinpSQLpn+d5wH8lWlN2w1a2T7XCW --profile leeduckgo"
             )
  end

  test "sui client call" do
    line =
      "sui client call --function buy_ham --module sandwich --package 0x08204ed92afcfdf9d0f6727a2c7d40db93a059d8 --args args1 args2 --gas gas_obj --gas-budget 30000"

    assert %{
             :args => ["args1", "args2"],
             :cli => :sui_client,
             :cmd => :call,
             :function => ["buy_ham"],
             :module => ["sandwich"],
             :package => ["0x08204ed92afcfdf9d0f6727a2c7d40db93a059d8"],
             :gas => ["gas_obj"],
             :"gas-budget" => ["30000"]
           } = MoveE2ETestTool.SuiCliParser.parse_cmd(line)
  end

  test "sui client transfer-sui" do
    line =
      "sui client transfer-sui --to 0x313c133acaf25103aae40544003195e1a3bb7d5b2b11fd4c6ec61af16bcdb968 --sui-coin-object-id 0x3a5f70f0bedb661f1e8bc596e308317edb0bdccc5bc86207b45f01db1aad5ddf --gas-budget 2000"

    assert %{
             cli: :sui_client,
             cmd: :"transfer-sui",
             "gas-budget": ["2000"],
             "sui-coin-object-id": [
               "0x3a5f70f0bedb661f1e8bc596e308317edb0bdccc5bc86207b45f01db1aad5ddf"
             ],
             to: ["0x313c133acaf25103aae40544003195e1a3bb7d5b2b11fd4c6ec61af16bcdb968"]
           } = MoveE2ETestTool.SuiCliParser.parse_cmd(line)
  end

  def script() do
    "sui client new-address secp256k1
    # 导入一个已有地址
    # 执行 ex 特有的 script

    sui client import-address AKpjfApmHx8FbjrRRSrUlF6ITigjP8NMS1ip4JdqPp5g
    # ex_script: set contract [contract_addr_str]

    # 查看已有地址的 gas 费用
    sui client gas
    # buy_bread
    sui client call --function buy_bread --module sandwich --package 0x08204ed92afcfdf9d0f6727a2c7d40db93a059d8 --args args1 args2 --gas gas_obj --gas-budget 30000
    # check if there is a bread
    # // TODO
    # buy_ham
    sui client call --function buy_ham --module sandwich --package 0x08204ed92afcfdf9d0f6727a2c7d40db93a059d8 --args args1 args2 --gas gas_obj --gas-budget 30000
    # check if there is a ham
    a=a
    #"
  end
end
