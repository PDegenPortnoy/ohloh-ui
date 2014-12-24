class String
  def strip_tags
    gsub(/<.*?>/, '')
  end

  def strip_tags_preserve_line_breaks
    html = CGI.unescapeHTML(self).gsub(/\r/, '')

    # Preserve line-breaking tags by converting them to carriage returns
    html.gsub!(/<br\s*\/?>\s*\n?/, "\n")
    html.gsub!(/<\/p>\s*\n?/, "\n\n")
    html.gsub!(/<p\s*\/>\s*\n?/, "\n\n")

    text = html.strip_tags

    # Restore line-breaking tags
    text.gsub!(/\n(\s*\n)+/, '<br/><br/>')
    text.gsub!(/\n/, '<br/>')

    # Strip leading and trailing breaks
    text.gsub!(/^(<br\/>)+/, '')
    text.gsub!(/(<br\/>)+$/, '')

    text
  end

  def fix_encoding_if_invalid!
    unless valid_encoding?
      encode!('utf-8', 'binary', invalid: :replace, undef: :replace)
    end
    force_encoding('utf-8')
    self
  end
end
