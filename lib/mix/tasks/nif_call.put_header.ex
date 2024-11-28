defmodule Mix.Tasks.NifCall.PutHeader do
  @shortdoc "Put bundled nif_call.h header file into the project"

  @moduledoc """
  A task responsible for putting the bundled nif_call.h header file into the project.
  """

  use Mix.Task

  require Logger

  @switches [
    dir: :string,
    overwrite: :boolean
  ]

  @nif_call_h File.read!(Path.expand(Path.join([__DIR__, "../../..", "nif_call.h"])))
  @impl true
  def run(flags) when is_list(flags) do
    {options, _args, _invalid} = OptionParser.parse(flags, strict: @switches)
    target_dir = Keyword.get(options, :dir, "c_src")
    overwrite? = Keyword.get(options, :overwrite, false)

    filepath = Path.join(target_dir, "nif_call.h")
    exists? = File.exists?(filepath)

    cond do
      exists? && !overwrite? ->
        Logger.warning(
          "nif_call.h already exists in #{target_dir}, please use --overwrite to overwrite the existing file."
        )

      exists? ->
        Logger.info(
          "nif_call.h already exists in #{target_dir}, overwriting it with the bundled nif_call.h."
        )

      true ->
        File.write!(filepath, @nif_call_h)
        Logger.info("nif_call.h has been put into #{target_dir}.")
    end

    :ok
  end
end
