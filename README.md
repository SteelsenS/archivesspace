# Getting started

The quickest way to get ArchivesSpace up and running is to download
the latest distribution .zip file from the following URL:

  https://github.com/archivesspace/archivesspace/wiki/Downloads

You will need to have Java 1.6 installed on your machine, but
everything else you need is included in the .zip file.

When you extract the .zip file, it will create a directory called
`archivesspace`.  To run the system, just execute the appropriate
startup script for your platform.  On Linux and OSX that's:

     # Runs as a daemon--use "stop" to shut down.
     ./archivesspace.sh start

and for Windows:

     archivesspace.bat

The system will send its log messages to the file
`logs/archivesspace.out`, so you can watch that file to see what's
happening.  After a minute or so, you should be able to point your
browser to http://localhost:3000/ and access the ArchivesSpace
application.


# First steps

To start using the application, log in using the adminstrator account:

* Username: `admin`
* Password: `admin`

Once logged in, you can create a new repository by selecting "Create a
repository" from the drop-down menu at the top right hand side of the
screen.  Once you have created a repository, you can log out and
register new user accounts from the link in the log-in form.


# Running ArchivesSpace with a custom configuration file

Under your `archivesspace` directory you will see a directory called
`config` which contains a file called `config.rb`.  By modifying this
file, you can override the defaults that ArchivesSpace ships with:
changing things like the ports it listens on and where it puts its data.


# Running ArchivesSpace against MySQL

The ArchivesSpace distribution runs against an embedded database by
default, but it's a good idea to run against MySQL for production
use.  To do this, create an empty database in MySQL and grant access
to a dedicated ArchivesSpace user (this example uses username `as` and
password `as123`):

         $ mysql -uroot -p

         mysql> create database archivesspace default character set utf8;
         Query OK, 1 row affected (0.08 sec)

         mysql> grant all on archivesspace.* to 'as'@'localhost' identified by 'as123';
         Query OK, 0 rows affected (0.21 sec)

Then, modify your `config/config.rb` file to refer to your MySQL
database:

     AppConfig[:db_url] = "jdbc:mysql://localhost:3306/archivesspace?user=as&password=as123&useUnicode=true&characterEncoding=UTF-8"

When you restart your ArchivesSpace instance it will connect to MySQL
and notice its tables haven't been created yet.  To create them,
browse to http://localhost:4567/setup and follow the prompts.  Once
the tables have been created, restart the application once again.


# Configuring LDAP authentication

ArchivesSpace can be configured to authenticate against one or more
LDAP directories by specifying them in the application's configuration
file.  When a user logs in, each authentication source is tried in
order until one matches or all sources are exhausted.

Here's a minimal example of LDAP authentication:

     AppConfig[:authentication_sources] = [{
                                             :model => 'LDAPAuth',
                                             :hostname => 'ldap.example.com',
                                             :port => 389,
                                             :base_dn => 'ou=people,dc=example,dc=com',
                                             :username_attribute => 'uid',
                                             :attribute_map => {:cn => :name},
     }]

With this configuration, ArchivesSpace performs authentication by
connecting to `ldap://ldap.example.com:389/`, binding anonymously,
searching the `ou=people,dc=example,dc=com` tree for `uid = <username>`. 

If the user is found, ArchivesSpace authenticates them by
binding using the password specified.  Finally, the `:attribute_map`
entry specifies how LDAP attributes should be mapped to ArchivesSpace
user attributes (mapping LDAP's `cn` to ArchivesSpace's `name` in the
above example).

Many LDAP directories don't support anonymous binding.  To integrate
with such a directory, you will need to specify the username and
password of a user with permission to connect to the directory and
search for other users.  Modifying the previous example for this case
looks like this:


     AppConfig[:authentication_sources] = [{
                                             :model => 'LDAPAuth',
                                             :hostname => 'ldap.example.com',
                                             :port => 389,
                                             :base_dn => 'ou=people,dc=example,dc=com',
                                             :username_attribute => 'uid',
                                             :attribute_map => {:cn => :name},
                                             :bind_dn => 'uid=archivesspace_auth,ou=system,dc=example,dc=com',
                                             :bind_password => 'secretsquirrel',
     }]


Finally, some LDAP directories enforce the use of SSL encryption.  To
configure ArchivesSpace to connect via LDAPS, change the port as
appropriate and specify the `encryption` option:

     AppConfig[:authentication_sources] = [{
                                             :model => 'LDAPAuth',
                                             :hostname => 'ldap.example.com',
                                             :port => 636,
                                             :base_dn => 'ou=people,dc=example,dc=com',
                                             :username_attribute => 'uid',
                                             :attribute_map => {:cn => :name},
                                             :bind_dn => 'uid=archivesspace_auth,ou=system,dc=example,dc=com',
                                             :bind_password => 'secretsquirrel',
                                             :encryption => :simple_tls,
     }]


# Further documentation

Latest documentation is published at [http://hudmol.github.com/archivesspace/](http://hudmol.github.com/archivesspace/)
