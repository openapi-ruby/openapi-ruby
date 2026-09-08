# frozen_string_literal: true

module OpenapiRuby
  # Parameters are declared in snake_case so `let(:page_size)` and
  # `params: {page_size: 1}` stay idiomatic Ruby. With `camelize_keys` on, the
  # name that reaches the document *and* the wire is camelCased, so parameters
  # match the component keys instead of contradicting them.
  #
  # Header parameters keep their declared spelling: HTTP header names are
  # conventionally hyphenated and matched case-insensitively, so camelizing
  # them would rename headers nobody asked to rename.
  module ParameterNames
    module_function

    def camelize?
      OpenapiRuby.configuration.camelize_keys
    end

    def camelize(name)
      return name.to_s unless camelize?

      Components::KeyTransformer.camelize(name)
    end

    # The name a declared parameter carries in the document and on the wire.
    def wire_name(param)
      name = param["name"] || param[:name]
      return nil if name.nil?
      return name.to_s if header?(param)

      camelize(name)
    end

    # Both spellings of a declared parameter. Value lookups go through this so a
    # caller that passes the declared name still resolves after the wire name
    # diverged from it.
    def lookup_names(param)
      declared = (param["name"] || param[:name])&.to_s
      return [] unless declared

      [declared, wire_name(param)].compact.uniq
    end

    def parameters_for_document(parameters)
      return parameters unless camelize?

      parameters.map do |param|
        wire = wire_name(param)
        next param if wire.nil? || wire == param["name"].to_s

        param.merge("name" => wire)
      end
    end

    # `/users/{user_id}` -> `/users/{userId}`. The template variables have to
    # travel with the parameter names: OpenAPI requires each one to be backed by
    # a path parameter of the same name.
    def in_template(template)
      return template unless camelize?

      template.gsub(/\{(\w+)\}/) { "{#{camelize(::Regexp.last_match(1))}}" }
    end

    # Rename the keys of a request value hash from their declared spelling to
    # the wire spelling. Keys that match no declared parameter are left alone —
    # undeclared params are passed through as the caller wrote them.
    def rename_keys(values, parameters)
      return values unless camelize?

      mapping = parameters.each_with_object({}) do |param, acc|
        declared = (param["name"] || param[:name])&.to_s
        next unless declared

        wire = wire_name(param)
        acc[declared] = wire if wire && wire != declared
      end
      return values if mapping.empty?

      values.each_with_object({}) do |(key, value), acc|
        renamed = mapping[key.to_s]
        acc[renamed.nil? ? key : renamed] = value
      end
    end

    def header?(param)
      (param["in"] || param[:in]).to_s == "header"
    end
  end
end
