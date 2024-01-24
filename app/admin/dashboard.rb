# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Parsing Logs" do
          table_for ParsingLog.last(24).order('id DESC') do
            column("Start date") { |i| i.start_date }
            column("End date") { |i| i.end_date }
            column("Run count rows") { |i| i.count_rows }
          end
        end
        if ParsingLog.count > 0
          div class: 'dashboard_link' do
            link_to 'Посмотреть все', admin_parsing_logs_path
          end
        end
      end
    end
  end
end
