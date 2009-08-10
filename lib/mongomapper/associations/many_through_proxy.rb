module MongoMapper
  module Associations
    class ManyThroughProxy < ManyDocumentsProxy
      def find(*args)
        options = args.extract_options!

        resultset = real_assoc.klass.find(*args << scoped_options(options))
        return if resultset.nil?

        if resultset.kind_of?(Array)
          resultset.map do |g|
            g.send(through_field)
          end
        else
          resultset.send(through_field)
        end
      end

      private
      def apply_scope(doc)
        field_id = through_field_id
        options = { :field_id => through_field_id,
                    :class => real_proxy.klass,
                    :foreign_key => foreign_key,
                    :owner_id => @owner.id
                  }

        identifier = "_save_#{through_field}_membership"
        save_membership_on_create(identifier, doc, options)

        doc
      end

      def real_assoc
        @real_assoc ||= klass.associations[@association.options[:through]]
      end

      def real_proxy
        @real_proxy ||= @owner.send(:get_proxy, real_assoc)
      end

      def through_field
        @through_field ||= @association.class_name.underscore
      end

      def through_field_id
        @through_field_id ||= "#{@association.class_name.underscore}_id"
      end

      def save_membership_on_create(identifier, doc, options)
        if !doc.class.after_save_callback_chain.detect{|c| c.method == identifier }
          doc.class.send(:define_method, identifier, lambda {
            puts "SAVE GROUP!!! #{options[:field_id]} = #{self.id}"
            group_membership = options[:class].new({ options[:foreign_key] => options[:owner_id]})

            group_membership.send("#{options[:field_id]}=", self.id)
            group_membership.save
          })
          doc.class.after_save identifier
        end
      end
    end
  end
end
