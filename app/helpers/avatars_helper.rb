require "zlib"

module AvatarsHelper
  AVATAR_COLORS = %w[
    #C20F45
  ]

  def avatar_background_color(user)
    AVATAR_COLORS[Zlib.crc32(user.to_param) % AVATAR_COLORS.size]
  end

  def avatar_tag(user, hidden_for_screen_reader: false, **options)
    link_to user_path(user), class: class_names("avatar btn btn--circle", options.delete(:class)), data: { turbo_frame: "_top" },
      aria: { hidden: hidden_for_screen_reader, label: user.name },
      tabindex: hidden_for_screen_reader ? -1 : nil,
      **options do
      avatar_image_tag(user)
    end
  end

  def mail_avatar_tag(user, size: 48, **options)
    if user.avatar.attached?
      image_tag user_avatar_url(user), alt: user.name, class: "avatar", size: size, **options
    else
      tag.span class: "avatar", style: "background-color: #{avatar_background_color(user)};" do
        user.initials
      end
    end
  end

  def avatar_preview_tag(user, hidden_for_screen_reader: false, **options)
    tag.span class: class_names("avatar", options.delete(:class)),
      aria: { hidden: hidden_for_screen_reader, label: user.name },
      tabindex: hidden_for_screen_reader ? -1 : nil do
      avatar_image_tag(user, **options)
    end
  end

  def avatar_image_tag(user, **options)
    image_tag user_avatar_url(user, script_name: user.account.slug), aria: { hidden: "true" }, size: 48, title: user.name, **options
  end
end
