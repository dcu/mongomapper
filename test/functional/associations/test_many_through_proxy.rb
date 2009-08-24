require 'test_helper'
require 'models'

class ManyThroughProxyTest < Test::Unit::TestCase
  def setup
    clear_all_collections
  end

  should "default reader to empty array" do
    Account.new.users.should == []
    Account.new.account_memberships.should == []
    AccountUser.new.accounts.should == []
    AccountUser.new.account_memberships.should == []
  end

  should "allow adding to assiciation like it were an array" do
    account = Account.new
    account.users << AccountUser.new
    account.users.push AccountUser.new
    account.users.concat AccountUser.new
    account.users.size.should == 3
  end

  should "be able to replace the association" do
    account = Account.create(:name => 'mongous')

    lambda {
      account.users = [
        AccountUser.new(:login => "dcu"),
        AccountUser.new(:login => "jnunemaker"),
        AccountUser.new(:login => "djsun")
      ]
    }.should change { AccountUser.count }.by(3)

    from_db = Account.find(account.id)
    users = from_db.users.all :order => "created_at desc"
    users.size.should == 3
    users[0].login.should == 'dcu'
    users[1].login.should == 'jnunemaker'
    users[2].login.should == 'djsun'
  end

  should "correctly store docs when using <<, push and concat" do
    account = Account.new
    account.users <<      AccountUser.new(:login => 'dave')
    account.users.push    AccountUser.new(:login => 'john')
    account.users.concat  AccountUser.new(:login => 'george')

    from_db = Account.find(account.id)
    users = from_db.users.all :order => "created_at asc"
    users[0].login.should == 'dave'
    users[1].login.should == 'john'
    users[2].login.should == 'george'
  end

  context "build" do
    should "assign foreign key" do
      account = Account.create
      membership = account.account_memberships.build
      membership.account_id.should == account.id
    end

    should "allow assigning attributes" do
      account = Account.create
      user = account.users.build(:login => 'foobar')
      user.login.should == 'foobar'
    end
  end

  context "create" do
    should "assign foreign key" do
      user = AccountUser.create(:login => 'foobar')
      membership = user.account_memberships.create
      membership.account_user_id.should == user.id
    end

    should "save record" do
      user = AccountUser.create
      lambda {
        user.accounts.create
      }.should change { Account.count }
    end

    should "allow passing attributes" do
      account = Account.create
      user = account.users.create(:login => 'foobar')
      user.login.should == 'foobar'
    end
  end

  context "count" do
    should "work scoped to association" do
      account = Account.create
      3.times { |i| account.users.create(:login => "foobar#{i}") }

      other_account = Account.create
      2.times { |i| other_account.users.create(:login => "foobar#{i}") }

      account.account_memberships.count.should == 3
      other_account.account_memberships.count.should == 2
      account.users.count.should == 3
      other_account.users.count.should == 2
    end

    should "work with conditions" do
      account = Account.create
      account.users.create(:login => 'foo')
      account.users.create(:login => 'bar')
      account.users.create(:login => 'baz')

      account.users.count(:login => 'foo').should == 1
    end
  end

#   context "Finding scoped to association" do
#     setup do
#       @lounge = Account.create(:name => 'Lounge')
#       @lm1 = Message.create(:login => 'Loungin!', :position => 1)
#       @lm2 = Message.create(:login => 'I love loungin!', :position => 2)
#       @lounge.users = [@lm1, @lm2]
#       @lounge.save
#
#       @hall = Account.create(:name => 'Hall')
#       @hm1 = Message.create(:login => 'Do not fall in the hall', :position => 1)
#       @hm2 = Message.create(:login => 'Hall the king!', :position => 2)
#       @hm3 = Message.create(:login => 'Loungin!', :position => 3)
#       @hall.users = [@hm1, @hm2, @hm3]
#       @hall.save
#     end
#
#     context "with :all" do
#       should "work" do
#         @lounge.users.find(:all, :order => "position").should == [@lm1, @lm2]
#       end
#
#       should "work with conditions" do
#         users = @lounge.users.find(:all, :conditions => {:login => 'Loungin!'}, :order => "position")
#         users.should == [@lm1]
#       end
#
#       should "work with order" do
#         users = @lounge.users.find(:all, :order => 'position desc')
#         users.should == [@lm2, @lm1]
#       end
#     end
#
#     context "with #all" do
#       should "work" do
#         @lounge.users.all(:order => "position").should == [@lm1, @lm2]
#       end
#
#       should "work with conditions" do
#         users = @lounge.users.all(:conditions => {:login => 'Loungin!'}, :order => "position")
#         users.should == [@lm1]
#       end
#
#       should "work with order" do
#         users = @lounge.users.all(:order => 'position desc')
#         users.should == [@lm2, @lm1]
#       end
#     end
#
#     context "with :first" do
#       should "work" do
#         @lounge.users.find(:first, :order => "position asc").should == @lm1
#       end
#
#       should "work with conditions" do
#         user = @lounge.users.find(:first, :conditions => {:login => 'I love loungin!'}, :order => "position asc")
#         user.should == @lm2
#       end
#     end
#
#     context "with #first" do
#       should "work" do
#         @lounge.users.first(:order => "position asc").should == @lm1
#       end
#
#       should "work with conditions" do
#         user = @lounge.users.first(:conditions => {:login => 'I love loungin!'}, :order => "position asc")
#         user.should == @lm2
#       end
#     end
#
#     context "with :last" do
#       should "work" do
#         @lounge.users.find(:last, :order => "position asc").should == @lm2
#       end
#
#       should "work with conditions" do
#         user = @lounge.users.find(:last, :conditions => {:login => 'Loungin!'}, :order => "position asc")
#         user.should == @lm1
#       end
#     end
#
#     context "with #last" do
#       should "work" do
#         @lounge.users.last(:order => "position asc").should == @lm2
#       end
#
#       should "work with conditions" do
#         user = @lounge.users.last(:conditions => {:login => 'Loungin!'}, :order => "position asc")
#         user.should == @lm1
#       end
#     end
#
#     context "with one id" do
#       should "work for id in association" do
#         @lounge.users.find(@lm2.id).should == @lm2
#       end
#
#       should "not work for id not in association" do
#         lambda {
#           @lounge.users.find(@hm2.id)
#         }.should raise_error(MongoMapper::DocumentNotFound)
#       end
#     end
#
#     context "with multiple ids" do
#       should "work for ids in association" do
#         users = @lounge.users.find(@lm1.id, @lm2.id)
#         users.should == [@lm1, @lm2]
#       end
#
#       should "not work for ids not in association" do
#         lambda {
#           @lounge.users.find(@lm1.id, @lm2.id, @hm2.id)
#         }.should raise_error(MongoMapper::DocumentNotFound)
#       end
#     end
#
#     context "with #paginate" do
#       setup do
#         @users = @hall.users.paginate(:per_page => 2, :page => 1, :order => 'position asc')
#       end
#
#       should "return total pages" do
#         @users.total_pages.should == 2
#       end
#
#       should "return total entries" do
#         @users.total_entries.should == 3
#       end
#
#       should "return the subject" do
#         @users.should == [@hm1, @hm2]
#       end
#     end
#   end
end
