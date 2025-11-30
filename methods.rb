##
# Methods to be imported into the main script.
#
# frozen_string_literal: true

# Return a copy of the given URI with a trailing slash added if missing.
def ensure_trailing_slash(uri)
  new_uri = uri.dup
  new_uri.path += '/' unless new_uri.path.end_with?('/')
  new_uri
end

# Tweak HTML converted from Markdown.
def postprocess_html(html)
  dom = Nokogiri::HTML5.fragment(html)

  # Handle links converted from internal links.
  dom.css('a.internal').each do |a|
    uri = URI(a['href'])

    # Strip the file extension.
    uri.path = Pathname(uri.path).sub_ext('').to_s

    a['href'] = uri.to_s
  end

  dom.to_html
end

# Generate the HTML file.
def generate_html_file(filename, page, html_template, options)
  # Render and tweak the body HTML.
  article_body_html = postprocess_html(page.formatted_data)

  # Check if the page contains LaTeX math-like text.
  has_math = page.text_data
    .lines(chomp: true)
    .any? { |line| line =~ /\$[^$]*[^$\s][^$]*\$/ }

  # Escape user-provided strings.
  [:main_heading, :author_name].each do |key|
    options[key] = CGI.escape_html(options[key]) if options[key]
  end

  options[:all_pages]&.map! do |page|
    page.merge(title: CGI.escape_html(page[:title]))
      .transform_keys(&:to_s) # Stringify symbol keys for Liquid.
  end

  # Render the full HTML.
  full_html = html_template.render!({
    site_name: ESCAPED_SITE_NAME,
    site_url: SITE_URL.to_s,

    publisher_name: ESCAPED_PUBLISHER_NAME,
    publisher_url: PUBLISHER_URL.to_s,
    publisher_logo_url: PUBLISHER_LOGO_URL.to_s,

    home_url: HOME_URL.to_s,
    license_url: LICENSE_URL.to_s,
    stylesheet_url: STYLESHEET_URL.to_s,

    has_math:,
    mathjax_config_script_url: MATHJAX_CONFIG_SCRIPT_URL.to_s,

    article_body_html:,

    **options
  }.transform_keys(&:to_s), {
    strict_variables: true,
    strict_filters: true,
  })

  # Write the HTML file.
  output_file = OUTPUT_DIRECTORY.join(filename)
  output_file.write(full_html)
end

# Generate a sitemap file.
def generate_sitemap_file(pages)
  xml = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <url>
        <loc>#{SITE_URL}</loc>
      </url>
  XML

  pages.each do |page|
    xml << <<~XML % page
      <url>
        <loc>%{canonical_url}</loc>
        <lastmod>%{modified_date_iso}</lastmod>
      </url>
    XML
  end

  xml << '</urlset>'

  sitemap_file = OUTPUT_DIRECTORY.join('sitemap.xml')
  sitemap_file.write(xml)
end
