defmodule Dialyxir.Warnings.Call do
  @moduledoc """
  The function call will not succeed.

  ## Example

      defmodule Example do
        def ok() do
          ok(:error)
        end

        def ok(:ok) do
          :ok
        end
      end
  """

  @behaviour Dialyxir.Warning

  alias Dialyxir.WarningHelpers

  @impl Dialyxir.Warning
  @spec warning() :: :call
  def warning(), do: :call

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short([_module, function | _]) do
    "The function call #{function} will not succeed."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([
        module,
        function,
        args,
        arg_positions,
        fail_reason,
        signature_args,
        signature_return,
        contract
      ]) do
    pretty_args = Erlex.shallow_pretty_print_args(args)
    pretty_module = Erlex.pretty_print(module)

    call_string =
      call_to_string(
        args,
        arg_positions,
        fail_reason,
        signature_args,
        signature_return,
        contract
      )

    """
    The function call will not succeed.

    #{pretty_module}.#{function}#{pretty_args}

    #{String.trim_trailing(call_string)}
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    @moduledoc
  end

  defp call_to_string(
        args,
        arg_positions,
        :only_sig,
        signature_args,
        _signature_return,
        {_overloaded?, _contract}
      ) do
    pretty_signature_args = Erlex.shallow_pretty_print_args(signature_args)

    diff = Erlex.pretty_print_diff(signature_args, args)

    if Enum.empty?(arg_positions) do
      # We do not know which argument(s) caused the failure
      """
      will never return since the success typing arguments are
      #{pretty_signature_args}
      #{diff}
      """
    else
      positions = WarningHelpers.form_position_string(arg_positions)

      pretty_args = Erlex.shallow_pretty_print_args(args)

      """
      will never return since the #{positions} arguments differ
      from the success typing arguments:
      #{pretty_args}
      #{diff}
      """
    end
  end

  defp call_to_string(
        args,
        arg_positions,
        :only_contract,
        _signature_args,
        _signature_return,
        {overloaded?, contract}
      ) do
    pretty_contract = Erlex.shallow_pretty_print_contract(contract)

    diff = Erlex.pretty_print_diff(contract, args)

    if Enum.empty?(arg_positions) || overloaded? do
      # We do not know which arguments caused the failure
      """
      breaks the contract
      #{pretty_contract}
      #{diff}
      """
    else
      position_string = WarningHelpers.form_position_string(arg_positions)

      """
      breaks the contract
      #{pretty_contract}

      in #{position_string} argument
      #{diff}
      """
    end
  end

  defp call_to_string(
        args,
        arg_positions,
        :both,
        signature_args,
        signature_return,
        {overloaded?, contract}
      ) do
    pretty_contract = Erlex.shallow_pretty_print_contract(contract)

    contract_diff = Erlex.pretty_print_diff(contract, args)

    pretty_print_signature =
      Erlex.shallow_pretty_print_contract("#{signature_args} -> #{signature_return}")

    signature_diff = Erlex.pretty_print_diff(signature_args, args)

    """
    will never return since the success typing is:
    #{pretty_print_signature}
    #{signature_diff}

    and the contract is
    #{pretty_contract}
    #{contract_diff}
    """
  end
end
