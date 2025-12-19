class CreateOAuthTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_tokens do |t|
      t.string :service
      t.string :endpoint
      t.string :token
      t.datetime :expiration_time

      t.timestamps
    end
  end
end
