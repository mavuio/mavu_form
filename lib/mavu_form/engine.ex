defmodule MavuForm.Engine do
  @moduledoc false

  import Phoenix.HTML

  @blocknames [
    :container,
    :input_block,
    :label_block,
    :wrapped_input,
    :wrapped_label,
    :raw_label,
    :updater
  ]

  @class_cmds [
    :prepend_classes,
    :append_classes,
    :set_classes,
    :replace_classes,
    :remove_classes,
    :update_classes
  ]

  @html_cmds [
    :prepend_html,
    :append_html,
    :set_html,
    :update_html
  ]

  @reserved_keywords [
    :items,
    :type,
    :using,
    :custom_fn,
    :theme
  ]

  def apply_cmds_on_classnames(classnames, cmds) when is_list(cmds) and is_list(classnames) do
    cmds
    |> Enum.reduce(classnames, &apply_cmd_on_classname/2)
  end

  def apply_cmds_on_classnames(classnames, cmds) when is_list(cmds) do
    apply_cmds_on_classnames(prepare_classname_list(classnames), cmds)
  end

  def apply_cmds_on_classnames(classnames, _), do: classnames
  def apply_cmds_on_classnames(classnames), do: classnames

  def apply_cmds_on_html(html, assigns, cmds)
      when is_map(assigns) and is_list(cmds) do
    # apply_cmd_on_html(hd(cmds), html, assigns)

    cmds
    # |> IO.inspect(label: "mwuits-debug 2021-01-21_17:52 ")
    |> Enum.reduce(html, fn cmd, html ->
      # cmd |> IO.inspect(label: "mwuits-debug 2021-01-21_17:51 apply")
      apply_cmd_on_html(cmd, html, assigns)
    end)
  end

  def apply_cmd_on_classname({:append_classes, new_classnames}, existing_classnames)
      when is_list(existing_classnames) do
    existing_classnames ++ prepare_classname_list(new_classnames)
  end

  def apply_cmd_on_classname({:prepend_classes, new_classnames}, existing_classnames)
      when is_list(existing_classnames) do
    prepare_classname_list(new_classnames) ++ existing_classnames
  end

  def apply_cmd_on_classname({:set_classes, new_classnames}, _existing_classnames) do
    prepare_classname_list(new_classnames)
  end

  def apply_cmd_on_classname({:replace_classes, replacement}, existing_classnames)
      when is_list(existing_classnames) and
             is_tuple(replacement) do
    apply_cmd_on_classname({:replace_classes, [replacement]}, existing_classnames)
  end

  def apply_cmd_on_classname({:replace_classes, replacements}, existing_classnames)
      when is_list(existing_classnames)
      when is_list(replacements) do
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
    |> Enum.filter(&MavuUtils.present?/1)
  end

  def apply_cmd_on_classname({:remove_classes, classnames_to_remove}, existing_classnames) do
    classnames_to_remove = prepare_classname_list(classnames_to_remove)

    existing_classnames
    |> Enum.filter(fn classname -> classname not in classnames_to_remove end)
  end

  def apply_cmd_on_classname({:update_classes, fun}, existing_classnames) do
    if not is_function(fun, 1) do
      raise "function passed to :update command has to have arity of 1"
    end

    fun.(existing_classnames)
    |> Enum.filter(&MavuUtils.present?/1)
  end

  def apply_cmd_on_classname({cmd, _}, _existing_classnames) do
    raise "command ':#{cmd}' was not recognized"
  end

  def apply_cmd_on_html({:prepend_html, new_html}, existing_html, _assigns) do
    html_escape([new_html, existing_html])
  end

  def apply_cmd_on_html({:append_html, new_html}, existing_html, _assigns) do
    html_escape([existing_html, new_html])
  end

  def apply_cmd_on_html({:set_html, new_html}, _existing_html, _assigns) do
    new_html
  end

  def apply_cmd_on_html({:update_html, :custom_fn}, existing_html, assigns)
      when is_map(assigns) do
    fun = assigns.opts[:custom_fn]

    if not is_function(fun) do
      raise ":custom_fn was not defined as top-level option, but referenced in block-options"
    end

    apply_cmd_on_html({:update_html, fun}, existing_html, assigns)
  end

  def apply_cmd_on_html({:update_html, fun}, existing_html, assigns)
      when is_map(assigns) do
    # fun |> IO.inspect(label: "mwuits-debug 2021-01-21_17:39 RUN :update_html ")

    if not is_function(fun, 1) do
      raise "function passed to :update command has to have arity of 1"
    end

    fun.(assigns |> Map.put(:inner_content, existing_html))
  end

  def apply_cmd_on_html({cmd, _}, _existing_html, _assigns) do
    raise "command ':#{cmd}' was not recognized"
    []
  end

  def prepare_classname_list(classnames) when is_binary(classnames) do
    classnames
    |> to_string()
    |> String.split(" ")
    |> Enum.filter(&MavuUtils.present?/1)
  end

  def prepare_classname_list(classnames) when is_list(classnames), do: classnames
  def prepare_classname_list(_), do: []

  def process_classes(classnames, blockname, assigns)
      when is_atom(blockname) do
    classlist = prepare_classname_list(classnames)

    cmds = get_class_cmds_for_block(blockname, assigns)

    apply_cmds_on_classnames(classlist, cmds)
    |> classnames_to_string()
  end

  def process_classes(classnames, _blockname, _assigns), do: classnames

  def process_html(html, blockname, assigns)
      when is_atom(blockname) do
    cmds = get_html_cmds_for_block(blockname, assigns)
    # |> IO.inspect(label: "mwuits-debug 2021-01-21_17:35 html cmds for #{blockname}")

    apply_cmds_on_html(html, assigns, cmds)
  end

  def process_html(html, _blockname, _assigns), do: html

  def get_opts_for_block(:raw_input, %{opts: opts} = _assigns),
    do: opts |> Keyword.drop(@blocknames)

  def get_opts_for_block(blockname, %{opts: opts} = _assigns) when is_atom(blockname) do
    optionkey = get_optionkey_for_blockname(blockname)

    case opts[optionkey] do
      block_opts when is_list(block_opts) -> block_opts
      _ -> []
    end
  end

  def get_class_cmds_for_block(blockname, assigns) when is_atom(blockname) and is_map(assigns) do
    get_opts_for_block(blockname, assigns)
    |> filter_class_cmds()
  end

  def get_html_cmds_for_block(blockname, assigns) when is_atom(blockname) and is_map(assigns) do
    get_opts_for_block(blockname, assigns)
    |> filter_html_cmds()
  end

  def filter_class_cmds(opts \\ []) do
    opts
    |> Enum.filter(fn {key, _val} -> key in @class_cmds end)
  end

  def filter_html_cmds(opts \\ []) do
    opts
    |> Enum.filter(fn {key, _val} -> key in @html_cmds end)
  end

  def get_tag_options_for_block(blockname, assigns) when is_atom(blockname) and is_map(assigns) do
    get_opts_for_block(blockname, assigns)
    |> clean_tag_options()
  end

  def clean_tag_options(opts) when is_list(opts) do
    opts
    |> Keyword.drop(@class_cmds ++ @html_cmds ++ @reserved_keywords)
  end

  def get_optionkey_for_blockname(blockname)
      when blockname in @blocknames,
      do: blockname

  def get_optionkey_for_blockname(_blockname), do: nil

  def classnames_to_string(classnames) when is_list(classnames), do: Enum.join(classnames, " ")
  def classnames_to_string(classnames) when is_binary(classnames), do: classnames
end
