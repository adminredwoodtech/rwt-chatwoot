class CreateCaptainTables < ActiveRecord::Migration[7.0]
  def up
    create_assistants
    create_documents
    create_assistant_responses
  end

  def down
    drop_table :captain_assistant_responses if table_exists?(:captain_assistant_responses)
    drop_table :captain_documents if table_exists?(:captain_documents)
    drop_table :captain_assistants if table_exists?(:captain_assistants)
  end

  private

  def create_assistants
    create_table :captain_assistants do |t|
      t.string :name, null: false
      t.bigint :account_id, null: false
      t.string :description

      t.timestamps
    end

    add_index :captain_assistants, :account_id
    add_index :captain_assistants, [:account_id, :name], unique: true
  end

  def create_documents
    create_table :captain_documents do |t|
      t.string :name, null: false
      t.string :external_link, null: false
      t.text :content
      t.bigint :assistant_id, null: false
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :captain_documents, :account_id
    add_index :captain_documents, :assistant_id
    add_index :captain_documents, [:assistant_id, :external_link], unique: true
  end

  def create_assistant_responses
    create_table :captain_assistant_responses do |t|
      t.string :question, null: false
      t.text :answer, null: false
      t.bigint :assistant_id, null: false
      t.bigint :document_id
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :captain_assistant_responses, :account_id
    add_index :captain_assistant_responses, :assistant_id
    add_index :captain_assistant_responses, :document_id
  end
end
