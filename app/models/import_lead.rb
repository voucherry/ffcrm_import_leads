# https://github.com/otilas/ffcrm_import_leads/blob/master/app/models/import_lead.rb
require 'csv'

class ImportLead
  def initialize(file)
    @file = file
  end

  def import_leads(assigned, convert_to_contacts)
    @assigned = assigned
    @promote_leads = convert_to_contacts

    import
  end

  # Sample Format (* = required)
  # "campaign_id","source","tag","created_at","first_name"*,"last_name"*,"email","phone","company","title","status","background_info","comments","street1","street2","city","state","zipcode","country"
  def import
    CSV.foreach(@file.path, :converters => :all, :return_headers => false, :headers => :first_row) do |row|
      campaign_id, source, tag, created_at, first_name, last_name,
      email, phone, company, title, status, background_info, comments,
      street1, street2, city, state, zip, country = *row.to_hash.values

      #TODO: implement smarter_csv and/or resque
      # https://github.com/tilo/smarter_csv
      # https://github.com/resque/resque

      #TODO: Handle duplicates on first_name, last_name, email (should also stop dup contacts)

      # entries.each do |entry|
      #   unless exists? :email => lead.email
      #     create!(
      #       :first_name        => lead.first_name,
      #       :last_name        => lead.last_name,
      #     )
      #   end
      # end

      # Lead.where('lower(email) = ?', "dillan@example.com").first

      #TODO: rails 4 Lead.find_or_initialize_by(email: email) without tap
      # Don't Allow Duplicates
      # lead = Lead.find_or_initialize_by_email(email).tap do |lead|
      #         lead.user_id = @assigned.id,
      #         lead.campaign_id = campaign_id.to_i,
      #         lead.source = source,
      #         lead.first_name = first_name,
      #         lead.last_name = last_name,
      #         lead.email = email,
      #         lead.phone = phone,
      #         lead.company = company,
      #         lead.title = title, lead.status = status,
      #         lead.background_info = background_info,
      #         lead.created_at = created_at.to_time
      #         end
      # lead.save!

      # Allow Duplicates
      lead = Lead.new(
        :user_id => @assigned.id,
        :campaign_id => campaign_id.to_i,
        :source => source,
        :first_name => first_name,
        :last_name => last_name,
        :email => email,
        :phone => phone,
        :company => company,
        :title => title, :status => status,
        :background_info => background_info,
        :created_at => created_at.to_time
        )

      lead.first_name = "INCOMPLETE" if lead.first_name.blank?
      lead.last_name = "INCOMPLETE" if lead.last_name.blank?

      # lead.access? = "Private | Public"
      lead.access = Setting.default_access

      lead.assignee = @assigned if @assigned.present?

      #TODO: Better validation on address fields.
      if zip
        lead.business_address = Address.new(:street1 => street1, :street2 => street2, :city => city, :state => state, :zipcode => zip, :country => country, :address_type => "Business")
      end

      lead.save!

      if @promote_leads

        if lead.company
          account_name = lead.company
        else
          account_name = lead.first_name + ' ' + lead.last_name + ' (Individual)'
        end

        #TODO: rails 4 Account.find_or_initialize_by(name: account_name)
        account = Account.find_or_initialize_by_name(account_name).tap do |account|
                    account.user_id = @assigned.id
                    account.assignee = @assigned if @assigned.present?
                    account.access = lead.access
                    account.category = 'customer'
                  end
        account.save!

        lead_account = { account: { id: account.id }, access: lead.access }

        @account, @opportunity, @contact = lead.promote(lead_account)

        #TODO: Consider handling duplicates on first_name, last_name, email
        contact = Contact.find(@contact)
        contact.tag_list.add(tag)
        contact.add_comment_by_user(comments, @assigned)
        contact.save!

        lead.convert
        lead.save!

        # Rails.logger.info "XXXXXXXX CONTACT CREATED! #{contact.inspect}"

      else
        lead.tag_list.add(tag)
        lead.add_comment_by_user(comments, @assigned)
        lead.save!
      end
    end
  end
end
