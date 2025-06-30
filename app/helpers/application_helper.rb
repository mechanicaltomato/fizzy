module ApplicationHelper
  def page_title_tag
    tag.title @page_title || "Fizzy"
  end

  def icon_tag(name, **options)
    tag.span class: class_names("icon icon--#{name}", options.delete(:class)), "aria-hidden": true, **options
  end

  def filterable_name(text)
    I18n.transliterate(text.to_s).downcase
  end
end
