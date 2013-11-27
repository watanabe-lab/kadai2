require 'ipaddr'

class IPAddr
  def to_a
    self.to_s.split( "." ).collect do | each |
      each.to_i
    end
  end
end


class EthernetHeader
  attr_accessor :macda, :macsa, :eth_type


  def initialize macda, macsa, eth_type
    @macda = macda
    @macsa = macsa
    @eth_type = eth_type
  end


  def pack
    ( @macda.to_a + @macsa.to_a + [ eth_type ] ).pack( "C12n" )
  end
end


class ARPPacket
  attr_accessor :type, :tha, :sha, :tpa, :spa


  def initialize type, tha, sha, tpa, spa
    @type = type
    @tha = tha
    @sha = sha
    @tpa = tpa
    @spa = spa
  end


  def pack
    eth_header = EthernetHeader.new( @tha, @sha, 0x0806 )

    # arp
    arp = [ 0x00, 0x01, 0x08, 0x00, 0x06, 0x04, 0x00, @type ]
    arp += @sha.to_a + @spa.to_a + @tha.to_a + @tpa.to_a

    while arp.length < 46 do
      arp += [ 0x00 ]
    end

    eth_header.pack + arp.pack( "C*" )
  end
end


class ARPRequest < ARPPacket
  def initialize sha, tpa, spa
    tha = [ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ]
    super( 1, tha, sha, tpa, spa )
  end
end


class ARPReply < ARPPacket
  def initialize tha, sha, tpa, spa
    super( 2, tha, sha, tpa, spa )
  end
end


module LoadBalancerUtils
  def create_arp_request_from sha, tpa, spa
    arp = ARPRequest.new( sha, tpa, spa )
    arp.pack
  end


  def create_arp_reply_from message, replyaddr
    arp = ARPReply.new( message.macsa, replyaddr, message.arp_spa, message.arp_tpa )
    arp.pack
  end

end
