Wiki::Plugin.define 'tag/support' do
  require 'hpricot'

  module TagSupport
    def self.included(base)
      return if base.respond_to? :define_tag
      base.extend(ClassMethods)
      base.class_eval { include InstanceMethods }
    end

    module InstanceMethods
      def handle_tags(engine, page, content)
        doc = Hpricot::XML(content)
        elements = []
        self.class.tags.each do |tag|
          name, method = tag
          (doc/name).each do |elem|
            elements << [method, elem]
            elem.swap "WIKI_TAG_#{elements.length-1}"
          end
        end
        content = doc.to_html
        page, content = engine[page, content]
        content.gsub!(/WIKI_TAG_(\d+)/) do |match|
          elem = elements[$1.to_i]
          if elem
            elem[0].bind(self).call(page, elem[1])
          else
            match
          end
        end
        [page, content]
      end
    end

    module ClassMethods
      attr_reader :tags

      def define_tag(tag, opts = {}, &block)
        if !@tags
          around_filter :handle_tags
          @tags = superclass.instance_variable_get(:@tags) || []
        end
        method = block.to_method(self)
        define_method("handle_tag_#{tag}") do |page, elem|
          if opts[:requires] && attr = [opts[:requires]].flatten.find {|a| elem.attributes[a.to_s].blank? }
            "<span class=\"error\">Attribute \"#{attr}\" is required for tag \"#{tag}\"</span>" if elem.attributes[attr.to_s].blank?
          else
            method.bind(self)[page, elem]
          end
        end
        @tags << [tag, instance_method("handle_tag_#{tag}")]
      end
    end
  end

  class Wiki::Engine
    include TagSupport
  end
end
