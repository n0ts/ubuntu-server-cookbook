#
# Cookbook Name:: ubuntu_server
# Attribute:: default
#
# Copyright 2013, Naoya Nakazawa
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

default[:ubuntu_server] = {
  :motd_tail => "",

  :sysctl => {
    :params_header => "",
    :params => "",
  },

  :ufw => {
    :enable => false,
    :before_rules => {
      :mangle => {},
      :nat => {},
      :allow_all => [ "eth0" ],
      :allow_port => {},
    },
    :default => {
      :input_policy   => "DROP",
      :output_policy  => "ACCEPT",
      :forward_policy => "DROP",
    },
    :sysctl => {
      :ip_forward => false,
      :ipv6       => false,
      :bridge     => false,
      :rp_filter  => [],
      :nf_conntrack_max => 0,
      :nf_conntrack_tcp_timeout_established => 0,
      :params_header => "",
      :params => "",
    },
  },

  :virt_type => "",

  :rc_local_params => "",
}
