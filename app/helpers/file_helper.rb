module FileHelper
  
  def file_form(**options)
    form_for :file, html: { class: "general file_form" }, url: post_file_path do |f|
      concat f.file_field :file
      concat f.text_field :name, placeholder: t("general.words.name")
      concat f.text_area :description, placeholder: t("general.words.description")
      concat f.hidden_field :category, value: options[:category] if options[:category].present?
      concat f.submit("Lataa")
    end
  end
  
  def list_files(files)
    general_table do
      files.each do |file|
        concat content_tag(:tr, tag.td(link_to file.name, file_path(file.id), target: :__blank) + tag.td(file.description) + tag.td(link_to "delete", delete_file_path(file.id), class: "material-icons", method: :delete, **are_you_sure_confirm))
      end
    end
  end
  
  def list_attached_files model, **options
    options[:files_name] ||= :attachments
    files_name = options[:files_name]
    if model.send(files_name).attached?
      concat "<hr>Tiedostot: ".html_safe if options[:show_title]

      tag.table class: 'attachments' do
        model.send(files_name).each do |attachment|
          concat (tag.tr data: { href: show_attachment_path(attachment.id), target: 'modal' } do
            concat (tag.td class: 'preview' do
              concat (
                if attachment.content_type.include?('image') && attachment.representable?
                  image_tag(attachment.representation(resize: '300x300'), style: 'max-height: 100px; max-width: 100px;')
                elsif attachment.content_type.include?('pdf') && attachment.representable?
                  image_tag(attachment.representation(resize: '300x300'), height: 100, style: 'max-width: 100px;')
                elsif attachment.content_type.include? 'audio'
                  # audio_tag(rails_blob_path(attachment, disposition: "inline"), controls: true)
                  tag.span(attachment.filename.extension.to_s.upcase, class: 'file_extension_symbol')
                elsif attachment.content_type.include?('video') && attachment.representable?
                  image_tag(attachment.representation(resize: '300x300'), height: 100)
                else
                  tag.span(attachment.filename.extension.to_s.upcase, class: 'file_extension_symbol')
                end
              )
            end)
            concat (tag.td do
              concat tag.b(shorten_filename attachment, 20) + ' '
              concat link_to('save_alt', rails_blob_path(attachment, disposition: "inline"), target: '__blank', class: 'download_file_icon material-icons')
              concat tag.br + t('general.words.created_at') + ' ' + l(attachment.created_at)
              concat (' ' + link_to('delete', delete_attachment_path(attachment.id), method: :delete, **are_you_sure_confirm, class: 'delete_file_icon material-icons')).html_safe if options[:show_delete]
            end)
          end)
        end
      end
    end

  end
  
  def default_file_field f, model, **options
    options[:files_name] ||= :attachments
    [f.file_field(options[:files_name], multiple: true),
    list_attached_files(model, show_delete: true, files_name: options[:files_name])].join(' ')
  end
  
  def single_file_field f, model, **options
    options[:attachment_name] ||= :attachment
    attachment = model.send(options[:attachment_name])
    if attachment.attached?
      [link_to(attachment.filename, rails_blob_path(attachment, disposition: "inline"), target: "__blank"),
      link_to('Poista', delete_attachment_path(attachment.id), method: :delete, **are_you_sure_confirm)].join(' ')
    else
      f.file_field options[:attachment_name], multiple: false, direct_upload: true
    end
  end
  
  def attachment_links attachments
    attachments.map do |attachment|
      link_to shorten_filename(attachment), rails_blob_path(attachment, disposition: "inline"), target: '__blank'
    end
  end
  
  def shorten_filename attachment, length = 20
    attachment.filename.base.to_s.truncate(length)+attachment.filename.extension_with_delimiter
  end
  
end
