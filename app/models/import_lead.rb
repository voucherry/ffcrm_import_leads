# https://github.com/otilas/ffcrm_import_leads/blob/master/app/models/import_lead.rb
require 'csv'

class ImportLead
  def initialize(file)
    @file = file
  end

  def import_leads(assigned, make_contact)
    @assigned = assigned
    @make_contact = (make_contact == '1' ? true : false)

    # Rails.logger.info "XXXXXXXX @make_contact#{make_contact}"

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

      # Rails.logger.info "XXXXXXXX created_at#{created_at}"

      if @make_contact
        # Don't Allow Duplicates
        contact = Contact.find_or_initialize_by_first_name_and_last_name_and_email(
                first_name,
                last_name,
                email
                ).tap do |contact|
                  contact.user_id = @assigned.id,
                  contact.source = source,
                  contact.first_name = first_name,
                  contact.last_name = last_name,
                  contact.email = email,
                  contact.phone = phone,
                  # contact.company = company,
                  contact.title = title,
                  # contact.status = status,
                  contact.background_info = process_bg_info(contact.background_info, background_info),
                  contact.created_at = created_at.to_time rescue Time.current
                end
        contact.save!

        contact.first_name = "INCOMPLETE" if contact.first_name.blank?
        contact.last_name = "INCOMPLETE" if contact.last_name.blank?
        # contact.access? = "Private | Public"
        contact.access = Setting.default_access
        contact.assignee = @assigned if @assigned.present?
        contact.tag_list.add(tag)
        contact.add_comment_by_user(comments, @assigned)

        contact.save!

        #TODO: Better validation on address fields.
        if zip
          contact.business_address = Address.new(:street1 => street1, :street2 => street2, :city => city, :state => state, :zipcode => zip, :country => country, :address_type => "Business")
        else
          puts "INCOMPLETE ADDRESS"
        end
        contact.save!

        #
        if contact.account_contact.nil?

          if company
            account_name = company
          else
            account_name = contact.first_name + ' ' + contact.last_name + ' (Individual)'
          end

          #TODO: rails 4 Account.find_or_initialize_by(name: account_name)
          account = Account.find_or_initialize_by_name(account_name).tap do |account|
                      account.user_id = @assigned.id
                      account.assignee = @assigned if @assigned.present?
                      account.access = contact.access
                      account.category = 'customer'
                    end
          account.save!

          contact.account_contact = AccountContact.new(:account => account, :contact => contact)

          # Rails.logger.info "XXXXXXXX ACCOUNT CONTACT CREATED! #{contact.account_contact.inspect}"

          # contact_account = { account: { id: account.id }, access: contact.access }
          # @account, @opportunity, @contact = contact.promote(contact_account)
          # contact = Contact.find(@contact)
        end

        # Rails.logger.info "XXXXXXXX CONTACT CREATED! #{contact.inspect}"

      else

        # Allow Duplicates
        # lead = Lead.new(
        #   :user_id => @assigned.id,
        #   :campaign_id => campaign_id.to_i,
        #   :source => source,
        #   :first_name => first_name,
        #   :last_name => last_name,
        #   :email => email,
        #   :phone => phone,
        #   :company => company,
        #   :title => title, :status => status,
        #   :background_info => background_info,
        #   :created_at => created_at.to_time
        #   )


        #TODO: rails 4 Lead.find_or_initialize_by(email: email) without tap
        # Don't Allow Duplicates
        lead = Lead.find_or_initialize_by_first_name_and_last_name_and_email(
                first_name,
                last_name,
                email
                ).tap do |lead|
                  lead.user_id = @assigned.id,
                  lead.campaign_id = campaign_id.to_i,
                  lead.source = source,
                  lead.first_name = first_name,
                  lead.last_name = last_name,
                  lead.email = email,
                  lead.phone = phone,
                  lead.company = company,
                  lead.title = title,
                  lead.status = status,
                  lead.background_info = process_bg_info(lead.background_info, background_info),
                  lead.created_at = created_at.to_time rescue Time.current
                end
        lead.save!

        lead.first_name = "INCOMPLETE" if lead.first_name.blank?
        lead.last_name = "INCOMPLETE" if lead.last_name.blank?

        # lead.access? = "Private | Public"
        lead.access = Setting.default_access
        lead.assignee = @assigned if @assigned.present?
        lead.tag_list.add(tag)
        lead.add_comment_by_user(comments, @assigned)
        lead.save!

        #TODO: Better validation on address fields.
        if zip
          lead.business_address = Address.new(:street1 => street1, :street2 => street2, :city => city, :state => state, :zipcode => zip, :country => country, :address_type => "Business")
        else
          puts "INCOMPLETE ADDRESS"
        end
        lead.save!

      end
    end


  end


  def process_lead

    # create_lead

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


  end

  def process_contact

    # create_contact
        #  id              :integer         not null, primary key
        #  user_id         :integer
        #  lead_id         :integer
        #  assigned_to     :integer
        #  reports_to      :integer
        #  first_name      :string(64)      default(""), not null
        #  last_name       :string(64)      default(""), not null
        #  access          :string(8)       default("Public")
        #  title           :string(64)
        #  department      :string(64)
        #  source          :string(32)
        #  email           :string(64)
        #  alt_email       :string(64)
        #  phone           :string(32)
        #  mobile          :string(32)
        #  skype           :string(128)
        #  fax             :string(32)
        #  blog            :string(128)
        #  linkedin        :string(128)
        #  facebook        :string(128)
        #  twitter         :string(128)
        #  born_on         :date
        #  do_not_call     :boolean         default(FALSE), not null
        #  background_info :string(255)
        #  deleted_at      :datetime
        #  created_at      :datetime
        #  updated_at      :datetime

    # create_account
    # create_account_contact

  end

  def process_address(import_address)
  end

  def process_bg_info(entity_bg_info, import_bg_info)

    if entity_bg_info.nil?
      bg_info = import_bg_info
    elsif import_bg_info.nil?
      bg_info = entity_bg_info
    elsif entity_bg_info.include? import_bg_info
      bg_info = entity_bg_info
    else
      bg_info = entity_bg_info+' ... '+import_bg_info
    end

    bg_info

  end

end
