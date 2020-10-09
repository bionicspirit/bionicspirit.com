require "nokogiri"
require "premailer"
require "cgi"

def to_absolute_url(site, url)
  if url =~ /^\//
    site['url'] + site['baseurl'] + url
  else
    url
  end
end

module Jekyll
  module MyUsefulFilters
    @@months = {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December'
    }

    def date_to_long_string(date)
      parsed = time(date)
      m = @@months[parsed.strftime("%-m").to_sym]
      d = parsed.strftime("%-d")
      y = parsed.strftime("%Y")
      m + " " + d + ", " + y
    end

    def to_css_id(name)
      name.gsub(/\W+/, "_")
    end

    def xml_smart_escape(str)
      if str.match(/['"><]/) || (str.include?("&") && !str.match(/&\w+;/))
        CGI.escapeHTML(str)
      else
        str
      end
    end

    def sort_by_date_desc(posts)
      posts.sort { |a, b| 
        -1 * (
          a['date'] <=> b['date'] ||
          a['slug'] <=> b['slug']
        )
      }
    end

    def sort_by_last_modified_at_desc(posts)
      posts.sort { |a, b| 
        -1 * (
          a['last_modified_at'] <=> b['last_modified_at'] ||
          a['date'] <=> b['date'] ||
          a['slug'] <=> b['slug']
        )
      }
    end
  end

  module MyRSSFilter
    @@site = Jekyll.configuration({})

    def rss_campaign_link(link, keyword, campaign="rss")
      l = if link.include? '?'
        link + "&"
      else
        link + "?"
      end

      l = l + "pk_campaign=#{campaign}"
      l = l + "&pk_kwd=" + keyword if keyword
      l
    end

    def rss_process(html, styles=nil)
      doc = Nokogiri::HTML(html)

      doc.css("img").each do |elem|
        elem["src"] = to_absolute_url(@@site, elem['src'])
        elem["style"] = "max-width: 100%; " + (elem["style"] || "")
      end

      doc.css("img.left").each do |elem|
        elem["src"] = to_absolute_url(@@site, elem['src'])
        elem["style"] = "float:left; margin-right:20px; margin-bottom:20px;" + (elem["style"] || "")
      end

      doc.css("img.right").each do |elem|
        elem["src"] = to_absolute_url(@@site, elem['src'])
        elem["style"] = "float:right; margin-left:20px; margin-left:20px;" + (elem["style"] || "")
      end

      doc.css("iframe").each do |elem|
        elem["style"] = "max-width: 100%; " + (elem["style"] || "")
      end

      doc.css("figure").each do |elem|
        elem["style"] = "max-width: 100%; " + (elem["style"] || "")
      end

      doc.css("a").each do |elem|
        elem["href"] = to_absolute_url(@@site, elem['href'])
      end

      doc.css("figcaption").each do |elem|
        elem.inner_html = "<p><em>" + elem.inner_html + "</em></p>"
      end

      body = doc.at_css("body")
      html1 = body ? body.inner_html : ""

      if styles
        html2 = "<style>#{styles}</style> #{html1}"
        premailer = Premailer.new(html2, with_html_string: true, drop_unmergeable_css_rules: true)
        html3 = premailer.to_inline_css
        
        premailer.warnings.each do |w|
          Jekyll.logger.warn("                    #{w[:message]} (#{w[:level]}) may not render properly in RSS client")
        end

        html3
      else
        html1
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::MyUsefulFilters)
Liquid::Template.register_filter(Jekyll::MyRSSFilter)
