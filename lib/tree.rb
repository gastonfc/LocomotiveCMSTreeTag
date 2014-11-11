class Tree < ::Liquid::Tag
        Syntax = /(#{::Liquid::Expression}+)?/

        def _parse(context)
          unless @m_content_type
            if @markup =~ Syntax
              @page = context.registers[:page]
              @site = context.registers[:site]

              @content_type_name = $1.gsub(/"|'/, '')
              @m_content_type = @site.content_types.where(slug: @content_type_name).first
              @content_type_page = @site.pages.where("slug.#{default_locale}" => @content_type_name).first

              @page_entry = get_current_entry(context)

              @options = { id: 'nav', depth: 1, class: '', active_class: 'on', bootstrap: false }
              @markup.scan(::Liquid::TagAttributes) { |key, value| @options[key.to_sym] = value.gsub(/"|'/, '') }

              @options[:exclude] = Regexp.new(@options[:exclude]) if @options[:exclude]

              @options[:add_attributes] = []
              if @options[:snippet]
                template = @options[:snippet].include?('{') ? @options[:snippet] : context[:site].snippets.where(slug: @options[:snippet] ).try(:first).try(:template)
                unless template.blank?
                  @options[:liquid_render] = ::Liquid::Template.parse(template)
                  @options[:add_attributes] = ['editable_elements']
                end
              end
            else
              raise ::Liquid::SyntaxError.new("Syntax Error in 'tree' - Valid syntax: tree")
            end
          end
        end

        def render(context)
          _parse(context)

          output = render_entry_children(context, nil, Integer(@options[:depth], 10)).join "\n"

          if @options[:no_wrapper] != 'true'
            list_class  = !@options[:class].blank? ? %( class="#{@options[:class]}") : ''
            output      = %{<nav id="#{@options[:id]}"#{list_class}><ul>\n#{output}</ul></nav>}
          end

          output
        end

        private

        # If the page is a template, it returns a string with the content-type currently showed
        def get_current_content_type(context)
          if @page.templatized?
            @page['fullpath'][default_locale].gsub(/\/.*$/, '')
          end
        end

        def default_locale
          @site.default_locale
        end

        def get_current_entry(context)
          entry_info = context['entry']
          unless entry_info.nil?
            current_content_type = get_current_content_type context
            slug = entry_info._slug
            entries = @site.content_types.where(slug: current_content_type).first.entries
            entries.where(_slug: slug).first
          end
        end

        # Determines root node for the list
        def fetch_entries(context)
          @entries ||= @m_content_type.entries
        end

        # Returns the page template of tree's content_type
        def get_tree_content_type_page(context)
        end

        def entry_in_active_branch?(entry)
          active_branch = @page_entry

          while active_branch
            if entry == active_branch
              return true
            else
              active_branch = active_branch.parent
            end
          end

          false
        end

        # Returns a list element, a link to the page and its children
        def render_entry_link(context, entry, css, depth)
          # selected = @page.fullpath =~ /^#{page.fullpath}(\/.*)?$/ ? " #{@options[:active_class]}" : ''

          # icon  = @options[:icon] ? '<span></span>' : ''
          # title = render_title(context, page)
          # label = %{#{icon if @options[:icon] != 'after' }#{title}#{icon if @options[:icon] == 'after' }}

          # link_options = caret = ''
          # href = File.join('/', @site.localized_page_fullpath(page))

          # if render_children_for_page?(page, depth) && bootstrap?
          #   css           += ' dropdown'
          #   link_options  = %{ class="dropdown-toggle" data-toggle="dropdown"}
          #   href          = '#'
          #   caret         = %{ <b class="caret"></b>}
          # end

          # output  = %{<li id="#{page.slug.to_s.dasherize}-link" class="link#{selected} #{css}">}
          # output << %{<a href="#{href}"#{link_options}>#{label}#{caret}</a>}
          # output << render_entry_children(context, page, depth.succ) if (depth.succ <= @options[:depth].to_i)
          # output << %{</li>}

          children = render_entry_children(context, entry, depth - 1)

          unless children.empty?
            submenu_class = !@options[:sub_class].blank? ? %( class="#{@options[:sub_class]}") : ''
            children.insert(0, ['<ul', submenu_class, '>'])
            children << '</ul>'
          end

          # current_locale = context['locale']
          # locale = (current_locale == default_locale) ? '' : current_locale

          base = @site.localized_page_fullpath(@content_type_page)

          href = File.join('/', base, entry._slug )

          if entry_in_active_branch?(entry)
            css << " #{@options[:active_class]}"
          end

          ['<li>',
           %{<a href="#{ href }"}, (%{ class="#{css}"} unless css.empty?), '>',
           entry.title,
           '</a>',
           children, '</li>'].flatten!.join ''
        end


        def render_children_for_page?(page, depth)
          depth.succ <= @options[:depth].to_i && page.children.reject { |c| !include_page?(c) }.any?
        end

        # Recursively creates a nested unordered list for the depth specified
        def render_entry_children(context, entry, depth)

          if depth > 0

            id = entry.id unless entry.nil?

            children = fetch_entries(context).where(parent_id: id) # find(entry[:children])

            # This probably could be improved
            children = children.to_a.sort_by! { |x| x.position_in_parent }

            # children = page.children_with_minimal_attributes(@options[:add_attributes]).reject { |c| !include_page?(c) }

            children.collect do |c|
              css = []
              css << 'first' if children.first == c
              css << 'last'  if children.last  == c

              render_entry_link(context, c, css.join(' '), depth)
            end
          else
            []
          end
        end

        def render_title(context, page)
          if @options[:liquid_render]
            context.stack do
              context['page'] = page
              @options[:liquid_render].render(context)
            end
          else
            page.title
          end
        end

        def bootstrap?
          @options[:bootstrap] == 'true'
        end

end

::Liquid::Template.register_tag('tree', Tree)
