require "locomotive_tree/version"
require "mongoid"
require "locomotive_liquid"

module LocomotiveTree

    class Tree < ::Liquid::Tag
        Syntax = /(#{::Liquid::Expression}+)?/

        def render(context)
          _parse(context)

          branch = current_tree_entry_branch context
          output = render_entry_children(context, branch).join "\n"

          if @options[:no_wrapper] != 'true'
            list_class  = !@options[:class].blank? ? %( class="#{@options[:class]}") : ''
            output      = %{<nav id="#{@options[:id]}"#{list_class}><ul>\n#{output}</ul></nav>}
          end

          output
        end

        private


        def build_options context
          @options = { id: 'nav', depth: 1, class: '', active_class: 'on', submenu_prefix: '' }
          @markup.scan(::Liquid::TagAttributes) { |key, value| @options[key.to_sym] = value.gsub(/"|'/, '') }
        end

        def default_locale
          @site.default_locale
        end

        def get_content_type_object content_type_name
          @site.content_types.where(slug: content_type_name).first
        end

        def get_content_type_template content_type
          @site.pages.where(target_klass_name: content_type.entries_class_name, templatized: true).first
        end

        def _parse(context)
          unless @site
            if @markup =~ Syntax
              @site = context.registers[:site]
              @page = context.registers[:page] # Current page 

              @tree_content_type_name = $1.gsub(/"|'/, '')
              @tree_content_type = get_content_type_object @tree_content_type_name

              @page_entry = get_current_entry_s_page context

              build_options context
            else
              raise ::Liquid::SyntaxError.new("Syntax Error in 'tree'")
            end
          end
        end

        # If the page is a template, it returns the related content_type
        def current_content_type
          if @page.templatized?
            @page['fullpath'][default_locale].gsub(/\/.*$/, '')
          end
        end

        def get_current_entry_s_page(context)
          entry_info = context['entry']
          unless entry_info.nil?
            slug = entry_info._slug
            entries = @site.content_types.where(slug: current_content_type).first.entries
            entries.where(_slug: slug).first
          end
        end

        # Determines root node for the list
        def fetch_entries(context)
          @entries ||= @tree_content_type.entries
        end

        def current_tree_entry context
          if current_content_type == @tree_content_type_name
            @page_entry
          else
            current_entry = context['entry']

            if current_entry.respond_to? :[]
              current_entry[@tree_content_type_name.singularize]
            end
          end
        end

        # Returns an array with the path from the current entry
        # (first element) to the root of the tree
        def current_tree_entry_branch context
          branch = []
          active_branch = current_tree_entry context

          while active_branch
            branch << active_branch
            active_branch = active_branch.parent
          end

          branch
        end

        # Returns the html code of a tree node
        #
        # [context] liquid's context for this tag
        # [branch] an array containg the result of *current_tree_entry_branch*
        # [entry] the tree node
        # [css] a string with classes for this node
        # [prefix] a string to prepend to each node title
        # [holder] if the parent node has the holder attribute, the _slug of it, nil otherwise.
        def render_entry_link(context, branch, entry, css, prefix, holder)

          selected = branch.include? entry

          if selected

            if holder
              node_holder = holder
            else
              node_holder = entry._slug if (entry.respond_to? :holder) and entry.holder
            end

            children = render_entry_children(context, branch, entry, @options[:submenu_prefix], node_holder)

            unless children.empty?
              submenu_class = !@options[:sub_class].blank? ? %( class="#{@options[:sub_class]}") : ''
              children.insert(0, ['<ul', submenu_class, '>'])
              children << '</ul>'
            end

            css << " #{@options[:active_class]}"
          else
            children = []
          end

          base = @site.localized_page_fullpath(get_content_type_template @tree_content_type).gsub(/\/[^\/]*$/, '')

          if holder
            href = File.join('/', base, "#{holder}\##{entry._slug}" )
          else
            href = File.join('/', base, entry._slug )
          end

          ['<li>',
           %{<a href="#{ href }"}, (%{ class="#{css}"} unless css.empty?), '>',
           prefix,
           entry.title,
           '</a>',
           children, '</li>'].flatten!.join ''
        end

        # Returns the children's html code of the parent node parameter
        #
        # [context] liquid's context for this tag
        # [branch] an array containg the result of *current_tree_entry_branch*
        # [parent] the parent entry node
        # [prefix] a string to prepend to each node title
        # [holder] if the parent node has the holder attribute, the _slug of it, nil otherwise.
        def render_entry_children(context, branch, parent=nil, prefix='', holder=nil)

          id = parent.id unless parent.nil?

          children = fetch_entries(context).where(parent_id: id) # find(entry[:children])

          # This probably could be improved
          children = children.to_a.sort_by! { |x| x.position_in_parent }

          # children = page.children_with_minimal_attributes(@options[:add_attributes]).reject { |c| !include_page?(c) }

          children.collect do |c|
            css = []
            css << 'first' if children.first == c
            css << 'last'  if children.last  == c

            render_entry_link(context, branch, c, css.join(' '), prefix, holder)
          end
        end

        ::Liquid::Template.register_tag('tree', Tree)
    end
end
