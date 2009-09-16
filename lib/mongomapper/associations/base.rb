module MongoMapper
  module Associations
    class Base
      attr_reader :type, :name, :options

      def initialize(type, name, options = {})
        @type, @name, @options = type, name, options
      end

      def class_name
        @class_name ||= begin
          if cn = options[:class_name]
            cn
          elsif many?
            name.to_s.singularize.camelize
          else
            name.to_s.camelize
          end
        end
      end

      def klass
        @klass ||= class_name.constantize
      end

      def many?
        @many_type ||= @type == :many
      end

      def belongs_to?
        @belongs_to_type ||= @type == :belongs_to
      end

      def polymorphic?
        !!@options[:polymorphic]
      end

      def through?
        !!@options[:through]
      end

      def as?
        !!@options[:as]
      end

      def type_key_name
        @type_key_name ||= many? ? '_type' : "#{as}_type"
      end

      def as
        @options[:as] || self.name
      end

      def foreign_key
        @options[:foreign_key] || "#{name}_id"
      end

      def ivar
        @ivar ||= "@_#{name}"
      end

      def embeddable?
        many? && klass.embeddable?
      end

      def proxy_class
        @proxy_class ||= begin
          if many?
            if self.klass.embeddable?
              raise ArgumentError, "many :through is not supported for embedded documents" if through?

              polymorphic? ? ManyEmbeddedPolymorphicProxy : ManyEmbeddedProxy
            else
              if polymorphic?
                ManyPolymorphicProxy
              elsif through?
                ManyThroughProxy
              elsif as?
                ManyDocumentsAsProxy
              else
                ManyProxy
              end
            end
          else
            polymorphic? ? BelongsToPolymorphicProxy : BelongsToProxy
          end
        end # end begin
      end # end proxy_class
    end
  end
end
