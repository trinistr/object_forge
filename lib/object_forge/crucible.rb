# frozen_string_literal: true

module ObjectForge
  class Crucible
    def initialize(attributes, sequences)
      @attributes = attributes
      @sequences = sequences
    end

    def resolve!
      @attributes.each do |name, definition|
        @attributes[name] = instance_eval(&definition) if definition.is_a?(Proc)
      end

      @attributes
    end

    private

    def method_missing(name)
      if @attributes.key?(name)
        if @attributes[name].is_a?(Proc)
          @attributes[name] = instance_eval(&@attributes[name])
        else
          @attributes[name]
        end
      else
        super
      end
    end

    def respond_to_missing?(name, _include_all)
      @attributes.key?(name) || super
    end
  end
end