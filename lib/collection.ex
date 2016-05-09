defmodule Hypermedia.Collection do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      Module.register_attribute __MODULE__, :attributes, accumulate: true, persist: false
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      def to_map(model), do: unquote(__MODULE__).to_map(model, __MODULE__)
  def __attributes__, do: @attributes
    end
  end

  defmacro embed_as(name, presenter) do
    attribute = {:embed_as, name}

    quote do
      @attributes unquote(attribute)

      def unquote(method_name(attribute))(models) do
        Enum.map(models, fn(model) ->
          Hypermedia.Representable.to_map(model, unquote(presenter))
        end)
      end
    end
  end

  def method_name({type, name}), do: method_name(type, name)
  def method_name(:embed_as, name), do: String.to_atom("#{name}")

  def add_embed(map, embed, value) do
    embeds = Map.put(Map.get(map, "_embedded", %{}), to_string(embed), value)
    Map.put(map, "_embedded", embeds)
  end

  def to_map(collection, module) do
    Enum.reduce(module.__attributes__, Map.new, fn({type, key} = attr, map) ->
      process_attribute(map, attr, apply(module, method_name(type, key), [collection]))
    end)
  end

  defp process_attribute(map, {:embed_as, key}, value), do: add_embed(map, key, value)
end
