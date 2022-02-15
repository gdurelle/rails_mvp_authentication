require "test_helper"
require "generators/rails_mvp_authentication/install_generator"

class RailsMvpAuthentication::InstallGeneratorTest < Rails::Generators::TestCase
  tests ::RailsMvpAuthentication::Generators::InstallGenerator
  destination Rails.root

  setup do
    backup_routes
  end

  teardown do
    remove_if_exists("db/migrate")
    remove_if_exists("app/models/current.rb")
    remove_if_exists("app/models/user.rb")
    remove_if_exists("Gemfile")
    restore_routes
  end

  test "creates migration for users table" do
    run_generator
    assert_migration "db/migrate/create_users_table.rb" do |migration|
      assert_match(/add_index :users_tables, :email, unique: true/, migration)
      assert_match(/t.string :email, null: false/, migration)
      assert_match(/t.string :password_digest, null: false/, migration)
    end
  end

  test "creates user model" do
    run_generator
    assert_file "app/models/user.rb"
  end

  test "does not error if there is no Gemfile" do
    assert_nothing_raised do
      run_generator
    end
  end

  test "adds bcrypt to Gemfile" do
    FileUtils.touch Rails.root.join("Gemfile")

    run_generator
    assert_file "Gemfile", /gem "bcrypt", "~> 3.1.7"/
  end

  test "uncomments bcrypt from Gemfile" do
    File.atomic_write(Rails.root.join("Gemfile")) do |file|
      file.write('# gem "bcrypt", "~> 3.1.7"')
    end

    run_generator
    assert_file "Gemfile", /gem "bcrypt", "~> 3.1.7"/
  end

  test "should add routes" do
    run_generator

    assert_file "config/routes.rb" do |file|
      assert_match(/post "sign_up", to: "users#create"/, file)
      assert_match(/get "sign_up", to: "users#new"/, file)
      assert_match(/put "account", to: "users#update"/, file)
      assert_match(/get "account", to: "users#edit"/, file)
      assert_match(/delete "account", to: "users#destroy"/, file)
      assert_match(/resources :confirmations, only: \[:create, :edit, :new\], param: :confirmation_token/, file)
      assert_match(/post "login", to: "sessions#create"/, file)
      assert_match(/delete "logout", to: "sessions#destroy"/, file)
      assert_match(/get "login", to: "sessions#new"/, file)
      assert_match(/resources :passwords, only: \[:create, :edit, :new, :update\], param: :password_reset_token/, file)
      assert_match(/resources :active_sessions, only: \[:destroy\] do/, file)
      assert_match(/delete "destroy_all"/, file)
    end
  end

  test "should add current model" do
    run_generator

    assert_file "app/models/current.rb"
  end

  def backup_routes
    copy_file Rails.root.join("config/routes.rb"), Rails.root.join("config/routes.rb.bak")
  end

  def remove_if_exists(path)
    full_path = Rails.root.join(path)
    FileUtils.rm_rf(full_path)
  end

  def restore_routes
    File.delete(Rails.root.join("config/routes.rb"))
    copy_file Rails.root.join("config/routes.rb.bak"), Rails.root.join("config/routes.rb")
    File.delete(Rails.root.join("config/routes.rb.bak"))
  end
end