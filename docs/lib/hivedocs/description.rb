module Hivedocs
  module Description
    module_function

    def derive(metadata_description:, body:, author:, category:, tags: [])
      explicit = clean_inline(metadata_description)
      return explicit unless explicit.nil? || explicit.empty?

      extracted = extract_from_body(body)
      return extracted unless extracted.nil? || extracted.empty?

      fallback_category = first_category(category, tags)
      "... #{author} went on and on about ##{fallback_category} ..."
    end

    def extract_from_body(body)
      return nil if body.nil? || body.strip.empty?

      text = body.gsub(/[​-‍﻿]/, '')
      text = text.gsub(/```.*?```/m, ' ')
      text = text.gsub(/^ {4}.*$/, ' ')
      text = text.gsub(/\{\%.*?\%\}/m, ' ')
      text = text.gsub(/!\[[^\]]*\]\([^\)]*\)/, ' ')
      text = text.gsub(/^\s{0,3}\#{1,6}\s+.*$/, ' ')
      text = text.gsub(/^\s*>.*$/, ' ')
      text = text.gsub(/^\s*[-*+]\s+.*$/, ' ')
      text = text.gsub(/^\s*\d+\.\s+.*$/, ' ')
      text = text.gsub(/\[([^\]]+)\]\([^\)]*\)/, '\\1')
      text = text.gsub(/https?:\/\/\S+/, ' ')
      text = text.gsub(/<[^>]+>/, ' ')

      paragraphs = text.split(/\n\s*\n/).map { |p| clean_inline(p) }.compact

      paragraphs.each do |paragraph|
        next if paragraph.empty?
        next if paragraph.length < 40
        next unless paragraph.match?(/[A-Za-z]/)
        next if paragraph.match?(/^[@#]/)

        sentence = paragraph.split(/(?<=[.!?])\s+/).find { |s| plausible_sentence?(s) }
        candidate = clean_inline(sentence || paragraph)
        next if candidate.nil? || candidate.empty?

        return truncate(candidate, 220)
      end

      nil
    end

    def plausible_sentence?(text)
      value = clean_inline(text)
      return false if value.nil? || value.empty?
      return false if value.length < 40
      return false unless value.match?(/[A-Za-z]/)
      return false if value.count(':') > 2 && value.length < 80
      return false if value.scan(/[A-Z0-9_]{8,}/).any?

      true
    end

    def clean_inline(text)
      return nil if text.nil?

      value = text.dup
      value = value.gsub(/\r/, ' ')
      value = value.gsub(/\n+/, ' ')
      value = value.gsub(/[`*_~#>\[\]]/, ' ')
      value = value.gsub(/\s+/, ' ').strip
      value = value.gsub(/^[-:;,.!\s]+/, '').gsub(/[-:;,.!\s]+$/, '').strip
      return nil if value.empty?

      value
    end

    def truncate(text, max)
      return text if text.length <= max

      clipped = text[0, max].sub(/\s+\S*$/, '').strip
      clipped.empty? ? text[0, max].strip : clipped
    end

    def first_category(category, tags)
      primary = clean_inline(category)
      return primary unless primary.nil? || primary.empty?

      Array(tags).map { |tag| clean_inline(tag) }.compact.find { |tag| !tag.empty? } || 'misc'
    end
  end
end
