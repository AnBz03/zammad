# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4657TimeAccountingSelector < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting
      .find_by(name: 'time_accounting_selector')
      .update!(description: 'Show time accounting dialog when updating matching tickets.')
  end
end
