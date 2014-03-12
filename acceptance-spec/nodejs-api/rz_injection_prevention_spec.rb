require "spec_helper"

describe "ProjectOccam::NodeJS::API" do

  let(:data)   { ProjectOccam::Data.instance }
  let(:config) { ProjectOccam.config }

  describe ".Image Service" do

    it "should return the README file" do
      uri = URI "http://127.0.0.1:#{config.image_svc_port}#{OCCAM_URI_ROOT}/image/README"
      res = Net::HTTP.get_response(uri)
      res.code.should == '200'
      res.body.should =~ /Occam images/
    end

    it "should bail on 404 when presented with URI encoded directory traversal using ..%2F" do
      uri = URI "http://127.0.0.1:#{config.image_svc_port}#{OCCAM_URI_ROOT}/image/..%2FGemfile"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should bail on 404 when presented with URI encoded directory traversal using %2E%2E%2F" do
      uri = URI "http://127.0.0.1:#{config.image_svc_port}#{OCCAM_URI_ROOT}/image/%2E%2E%2FGemfile"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should bail on 404 when presented with URI encoded directory traversal using %2E%2E%5C" do
      uri = URI "http://127.0.0.1:#{config.image_svc_port}#{OCCAM_URI_ROOT}/image/%2E%2E%5CGemfile"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should bail on 404 when presented with binary zero in path" do
      uri = URI "http://127.0.0.1:#{config.image_svc_port}#{OCCAM_URI_ROOT}/image/%00%2Fetc%2Fpassword"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should bail on 500 when presented with UTF-8 encoded directory traversal %C0%AF" do
      uri = URI "http://127.0.0.1:#{config.image_svc_port}#{OCCAM_URI_ROOT}/image/..%C0%AFGemfile"
      res = Net::HTTP.get_response(uri)
      res.code.should == '500'
    end

    it "should bail on 500 when presented with UTF-8 encoded directory traversal %C1%1C" do
      uri = URI "http://127.0.0.1:#{config.image_svc_port}#{OCCAM_URI_ROOT}/image/..%C1%1CGemfile"
      res = Net::HTTP.get_response(uri)
      res.code.should == '500'
    end

  end

  describe ".RESTful Interface" do

    it "should bail on 404 when presented with URI encoded directory traversal" do
      uri = URI "http://127.0.0.1:#{config.api_port}#{OCCAM_URI_ROOT}/api/..%2FGemfile"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should not do shell expansion and perform cat ~/.ssh/id_rsa" do
      uri = URI "http://127.0.0.1:#{config.api_port}#{OCCAM_URI_ROOT}/api/-V/&&/cd/~/&&/cd/.ssh/&&/cat/id_rsa/;"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should bail on 404 when presented with binary zeroes" do
      uri = URI "http://127.0.0.1:#{config.api_port}#{OCCAM_URI_ROOT}/api/-V/%00cd/~/&&/cd/.ssh/&&/cat/id_rsa/;"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should not do URI encoded shell expansion" do
      uri = URI "http://127.0.0.1:#{config.api_port}#{OCCAM_URI_ROOT}/api/-V/%20%26%26%20cat%20%7E%2F.ssh%2Fid_rsa/;"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should bail on 404 when presented with -x" do
      uri = URI "http://127.0.0.1:#{config.api_port}#{OCCAM_URI_ROOT}/api/-x"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should refuse to deliver the config slice" do
      uri = URI "http://127.0.0.1:#{config.api_port}#{OCCAM_URI_ROOT}/api/config"
      res = Net::HTTP.get_response(uri)
      res.code.should == '404'
    end

    it "should refuse to combine web call with -j option" do
      uri = URI "http://127.0.0.1:#{config.api_port}#{OCCAM_URI_ROOT}/api/-j/config"
      res = Net::HTTP.get_response(uri)
      res.code.should == '400'
    end
  end
end
