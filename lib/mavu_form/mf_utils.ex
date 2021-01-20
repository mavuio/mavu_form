defmodule MavuForm.MfUtils do
  @moduledoc false

  import MavuForm.MfHelpers

  @blocknames [
    :container,
    :input_block,
    :label_block,
    :wrapped_input,
    :wrapped_label,
    :raw_label
  ]

  @spec apply_cmds_on_classnames(any, any) :: any
  def apply_cmds_on_classnames(classnames, cmds) when is_list(cmds) and is_list(classnames) do
    cmds
    |> Enum.reduce(classnames, &apply_cmd_on_classname/2)
  end

  def apply_cmds_on_classnames(classnames, cmds) when is_list(cmds) do
    apply_cmds_on_classnames(prepare_classname_list(classnames), cmds)
  end

  def apply_cmds_on_classnames(classnames, _), do: classnames
  def apply_cmds_on_classnames(classnames), do: classnames

  def apply_cmd_on_classname({:append, new_classnames}, existing_classnames)
      when is_list(existing_classnames) do
    existing_classnames ++ prepare_classname_list(new_classnames)
  end

  def apply_cmd_on_classname({:prepend, new_classnames}, existing_classnames)
      when is_list(existing_classnames) do
    prepare_classname_list(new_classnames) ++ existing_classnames
  end

  def apply_cmd_on_classname({:set, new_classnames}, _existing_classnames) do
    prepare_classname_list(new_classnames)
  end

  def apply_cmd_on_classname({:replace, replacement}, existing_classnames)
      when is_list(existing_classnames) and
             is_tuple(replacement) do
    apply_cmd_on_classname({:replace, [replacement]}, existing_classnames)
  end

  def apply_cmd_on_classname({:replace, replacements}, existing_classnames)
      when is_list(existing_classnames)
      when is_list(replacements) do
    {existing_classnames, replacements} |> IO.inspect(label: "mwuits-debug 2021-01-17_18:26 ")

    existing_classnames
    |> Enum.map(fn classname ->
      replacements
      |> Enum.reduce(classname, fn {pattern, replacement}, classname ->
        cond do
          Regex.regex?(pattern) && String.match?(classname, pattern) -> replacement
          is_binary(pattern) && classname == pattern -> replacement
          true -> classname
        end
      end)
    end)
    |> Enum.filter(&present?/1)
  end

  def apply_cmd_on_classname({:remove, classnames_to_remove}, existing_classnames) do
    classnames_to_remove = prepare_classname_list(classnames_to_remove)

    existing_classnames
    |> Enum.filter(fn classname -> classname not in classnames_to_remove end)
  end

  def apply_cmd_on_classname({:update, fun}, existing_classnames) do
    if not is_function(fun, 1) do
      raise "function passed to :update command has to have arity of 1"
    end

    fun.(existing_classnames)
    |> Enum.filter(&present?/1)
  end

  def apply_cmd_on_classname({cmd, _}, _existing_classnames) do
    raise "command ':#{cmd}' was not recognized"
  end

  def prepare_classname_list(classnames) when is_binary(classnames) do
    classnames
    |> to_string()
    |> String.split(" ")
    |> Enum.filter(&present?/1)
  end

  def prepare_classname_list(classnames) when is_list(classnames), do: classnames
  def prepare_classname_list(_), do: []

  def process_classes(classnames, blockname, assigns)
      when is_atom(blockname) do
    classlist = prepare_classname_list(classnames)

    opts = get_opts_for_block(blockname, assigns)

    case opts[:classes] do
      cmds when is_list(cmds) -> apply_cmds_on_classnames(classlist, cmds)
      _ -> classlist
    end
    |> classnames_to_string()
  end

  def process_classes(classnames, _blockname, _assigns), do: classnames

  @spec get_opts_for_block(atom, %{opts: nil | maybe_improper_list | map}) :: maybe_improper_list
  def get_opts_for_block(:raw_input, %{opts: opts} = _assigns),
    do: opts |> Keyword.drop(@blocknames)

  def get_opts_for_block(blockname, %{opts: opts} = _assigns) when is_atom(blockname) do
    optionkey = get_optionkey_for_blockname(blockname)

    case opts[optionkey] do
      sub_opts when is_list(sub_opts) -> sub_opts
      _ -> []
    end
  end

  def get_tag_options_for_block(blockname, assigns) when is_atom(blockname) and is_map(assigns) do
    get_opts_for_block(blockname, assigns)
    |> clean_tag_options()
  end

  def clean_tag_options(opts) when is_list(opts) do
    opts
    |> Keyword.drop([:classes, :items, :type, :using])
  end

  def get_optionkey_for_blockname(blockname)
      when blockname in @blocknames,
      do: blockname

  def get_optionkey_for_blockname(_blockname), do: nil

  def classnames_to_string(classnames) when is_list(classnames), do: Enum.join(classnames, " ")
  def classnames_to_string(classnames) when is_binary(classnames), do: classnames
end
