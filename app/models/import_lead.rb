# https://github.com/otilas/ffcrm_import_leads/blob/master/app/models/import_lead.rb
require 'csv'

class ImportLead
  def initialize(file)
    @file = file
  end

  def import_assigned_to(assigned)
    @assigned = assigned

    import
  end

  # Sample Format
  # "campaign_id","source","tag","created_at","title","first_name","last_name","email","phone","company","status","background_info","comments","street1","street2","city","state","zipcode","country"
  def import
    CSV.foreach(@file.path, :converters => :all, :return_headers => false, :headers => :first_row) do |row|
      campaign_id, source, tag, created_at, title, first_name, last_name,
      email, phone, company, status, background_info, comments,
      street1, street2, city, state, zip, country = *row.to_hash.values

      lead = Lead.new(:campaign_id => campaign_id.to_i, :source => source,
        :title => title, :first_name => first_name, :last_name => last_name,
        :email => email, :phone => phone,  :company => company, :status => status,
        :background_info => background_info, :user_id => @assigned.id, :created_at => created_at)

      lead.first_name = "INCOMPLETE" if lead.first_name.blank?
      lead.last_name = "INCOMPLETE" if lead.last_name.blank?

      # lead.access? = "Private | Public"
      lead.access = Setting.default_access

      lead.business_address = Address.new(:street1 => street1, :street2 => street2, :city => city, :state => state, :zipcode => zip, :country => country, :address_type => "Business")

      lead.assignee = @assigned if @assigned.present?
      lead.save!

      # if promote_lead?
      #   @account, @opportunity, @contact = lead.promote(:account => lead.company)
      #   contact = Contact.find(@contact)
      #   contact.tag_list.add(tag)
      #   contact.add_comment_by_user(comments, @assigned)
      #   contact.save!
      # else
        lead.tag_list.add(tag)
        lead.add_comment_by_user(comments, @assigned)
        lead.save!
      # end
    end
  end
end
