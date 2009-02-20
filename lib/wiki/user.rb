require 'wiki/entry'
require 'wiki/utils'
require 'wiki/extensions'

module Wiki
  class User < Entry
    include Utils

    attr_accessor :email
    attr_reader :password
    question_accessor :anonymous
    transient :anonymous

    def initialize(name, password, email, anonymous)
      super(name)
      @email = email
      @anonymous = anonymous
      @password = crypt(password)
    end

    def change_password(oldpassword, password, confirm)
      forbid('Passwords do not match' => password != confirm,
             'Password is wrong'      => @password != crypt(oldpassword))
      @password = crypt(password)
    end

    def author
      "#{@name} <#{@email}>"
    end

    def save
      forbid(
        'E-Mail is invalid' => @email !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
        'Name is invalid'   => @name !~ /[\w.\-+_]+/,
        'Password is empty' => @password.blank?,
        'Anonymous'         => anonymous?
      )
      super
    end

    def self.anonymous(ip)
      new(ip, nil, "anonymous@#{ip}", true)
    end

    def self.authenticate(name, password)
      user = find(name)
      forbid('Wrong username or password' => !user || user.password != crypt(password))
      user
    end

    def self.create(name, password, confirm, email)
      forbid('Passwords do not match' => password != confirm,
             'User already exists'    => find(name))
      new(name, password, email, false).save
    end

    static do
      private
      def crypt(s)
        s.blank? ? s : Digest::SHA256.hexdigest(s)
      end
    end

  end
end
