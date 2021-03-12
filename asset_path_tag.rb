module Jekyll
    module AssetPath
        def self.get_post_path(page_id, collections)
            collections.each do |collection|
                doc = collection.docs.find { |doc| doc.id == page_id }
                if doc != nil
                    slug = Jekyll::VERSION  >= '3.0.0' ? doc.data["slug"] : doc.slug
                    return "#{collection.label}/#{slug}"
                end
            end
            
            return ""
        end
        
        class Tag < Liquid::Tag
            @markup = nil
            
            def initialize(tag_name, markup, tokens)
                @markup = markup.strip
                super
            end
            
            def render(context)
                if @markup.empty?
                    return "Error processing input, expected syntax: {% asset_path filename post_id %}"
                end
                
                filename, post_id = parse_parameters context
                path = post_path context, post_id
                
                path = File.dirname(path) if path =~ /\.\w+$/
                
                return "#{context.registers[:site].config['baseurl']}/assets/#{path}/#{filename}"\
                    .gsub(%r{/{2,}}, '/')
            end
            
            private
            
            def parse_parameters(context)
                parameters = Liquid::Template.parse(@markup).render context
                parameters.strip!
                
                if ['"', "'"].include? parameters[0]
                    last_quote_index = parameters.rindex(parameters[0])
                    filename = parameters[1...last_quote_index]
                    post_id = parameters[(last_quote_index + 1)..-1].strip
                    return filename, post_id
                end
                
                return parameters.split(/\s+/)
            end
            
            def post_path(context, post_id)
                page = context.environments.first['page']
                
                post_id = page['id'] if post_id.nil? || post_id.empty?
                
                if post_id
                    collections = context.registers[:site].collections.map { |c| c[1] }
                    return Jekyll.get_post_path(post_id, collections)
                else
                    return page['url']
                end
            end
        end
    end
end

Liquid::Template.register_tag('asset_path', Jekyll::AssetPath::Tag)
