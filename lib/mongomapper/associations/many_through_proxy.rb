module MongoMapper
  module Associations
    class ManyThroughProxy < ManyDocumentsProxy
      def find(*args)
        options = args.extract_options!

        resultset = real_assoc.klass.find(*args << scoped_options(options))
        return if resultset.nil?

        real_resultset(resultset)
      end

      def paginate(options)
        resultset = real_assoc.klass.paginate(scoped_options(options))
        real_resultset(resultset)
      end

      def count(conditions={})
        real_assoc.klass.count(conditions.deep_merge(scoped_conditions))
      end

      def save_dirty_memberships(doc)
        while group_membership = dirty_memberships.pop
          group_membership.send("#{through_field_id}=", doc.id)
          group_membership.save
        end
      end

      private
      def apply_scope(doc)
        group_membership = real_proxy.klass.new({foreign_key => @owner.id})

        dirty_memberships.push(group_membership)
        doc.dirty_object_memberships.push(self) # FIXME: is there a way to avoid this?
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

      def dirty_memberships
        @dirty_memberships ||= []
      end

      def real_resultset(resultset)
        if resultset.kind_of?(Array)
          resultset.map do |g|
            g.send(through_field)
          end
        else
          resultset.send(through_field)
        end
      end
    end
  end
end
