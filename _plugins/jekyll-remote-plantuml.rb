# The MIT License (MIT)
#
# Copyright (c) 2015 Patrick Allain
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'singleton';
require 'jekyll'
require 'digest'
require 'fileutils'
require 'open-uri'

# Config for plantuml plugin.
class PlantUmlConfig
    include Singleton

    DEFAULT = {
        :assets     => 'images/plantuml/',
        :type         => 'png',
        :encode       => 'encode64',
        :url          => 'http://www.plantuml.com/plantuml/png/{code}'
    }
end


class PlantUmlEncode64
    def initialize(input)
        @input = input;
    end

    # Public : proceed to the encoding for plantuml servlet
    #
    # Returns the encoded uml to send to the servlet
    def encode()
        require 'zlib';
        o = @input.force_encoding("utf-8");
        o = Zlib::Deflate.new(nil, -Zlib::MAX_WBITS).deflate(o, Zlib::FINISH)
        return PlantUmlEncode64.encode64(o);
    end

    # Internal : Encode is some special base 64.
    #
    # @param a deflate string
    # Returns a encoded string
    def self.encode64(input)
        len, i, out =  input.length, 0, "";
        while i < len do
            i1 = (i+1 < len) ? input[i+1].ord : 0;
            i2 = (i+2 < len) ? input[i+2].ord : 0;
            out += append3bytes(input[i].ord, i1, i2);
            i += 3;
        end
        return out
    end

    def self.encode6bit(b)
        if b < 10 then
        return (48 + b).chr;
        end

        b -= 10;
        if b < 26 then
        return (65 + b).chr;
        end

        b -= 26;
        if b < 26 then
        return (97 + b).chr;
        end

        b -= 26;
        if b == 0 then
            return '-';
        end

        return (b == 1) ? '_' : '?';
    end

    def self.append3bytes(b1, b2, b3)
        c1 = (b1 >> 2)
        c2 = ((b1 & 0x3) << 4) | (b2 >> 4)
        c3 = ((b2 & 0xF) << 2) | (b3 >> 6)
        c4 = b3 & 0x3F;
        r = encode6bit(c1 & 0x3F)
        r += encode6bit(c2 & 0x3F);
        r += encode6bit(c3 & 0x3F);
        return r + encode6bit(c4 & 0x3F);
    end
end


# Load data from a remote url.

#
# data is loaded once time. If we can found data in cache, just use
# the cache instead of making lot of remote call.
class RemoteLoader
    include Singleton

    # Callback for plain text content
    CONTENT_CALLBACKS = {
        'svg' => { :matcher => /\<\?xml.*?\>/, :replacement => '' }
    }

    # Initialization of the loaded dir
    #
    # Define the constant for the prefix url for binary file
    # and the directory where all file will be saved
    def initialize()
        conf = Jekyll.configuration({});
        pconf = PlantUmlConfig::DEFAULT.merge(conf['plantuml'] || {});
        dirname = conf['source'] + File::SEPARATOR + pconf[:assets].gsub(/\//, File::SEPARATOR).sub(/\/*$/, '').sub(/^\/*/, '');
        Jekyll.logger.info "Directory for storage remote data : %s" % [dirname],
        unless File.directory?(dirname) then
            Jekyll.logger.info "Create directory %s because this seems to be missing" % [dirname]
            FileUtils.mkdir_p(dirname)
        end
        @prefixUrl = pconf[:assets];
        @dirname = dirname;
    end

    # Internal : get the url from a config
    #
    # @param a hash with {:url, :code, :type } inside it
    # Returns the url for remote to retrieve
    def createRemoteUri(params)
        uri = params[:url];
        uri = uri.gsub(/\{code\}/, params[:code])
        uri = uri.gsub(/\{type\}/,  params[:type])
        return uri;
    end

    # Internal : get the data for the remote connection
    #
    # @param a hash with {:url, :code, :type } inside it
    # Returns the data as a hash
    def getData(params)
        ruri = createRemoteUri(params);
        fn = Digest::SHA256.hexdigest(ruri) + "." + params[:type]
        return { :remoteUri => ruri, :uri  => @prefixUrl + fn, :path => @dirname + File::SEPARATOR + fn }
    end

    # Public : get and saved the remote uri from a parameters hash
    # if the same content has already been downloaded previously,
    # just retrieve return the file information.
    #
    # @param a hash with {:url, :code, :type } inside it
    # Returns a hash with { :remoteUri, :uri, :path }
    def savedRemoteBinary(params)
        Jekyll.logger.debug "Plantuml remote loader params :", params;
        data = getData(params);
        unless File.exist?(data[:path]) then
            Jekyll.logger.info "Starting download content at %{remoteUri} done into file %{path}." % data;
            open(data[:path], 'wb') do |file|
                file << open(data[:remoteUri]).read
                Jekyll.logger.info "End download content at %{remoteUri} done into file %{path}." % data;
            end
        else
            Jekyll.logger.info "File %{path} has been found. Not download at %{remoteUri} will be made." % data;
        end
        return data;
    end

    # Public : get and saved the remote uri from a parameters hash
    # if the same content has already been downloaded previously,
    # just return the file content.
    #
    # @param a hash with {:url, :code, :type } inside it
    # Returns the content of the remote
    def loadText(params)
        d = savedRemoteBinary(params);
        content = File.read(d[:path]);
        tc = CONTENT_CALLBACKS[params[:type].downcase];
        if tc then
            content = content.gsub(tc[:matcher], tc[:replacement]);
        end
        return content;
    end
end


#

# Jekyll plugin for plantuml generation
#
# Any generation is store localy to prevent any further call
# on a remote provider.
module Jekyll

    class PlantUmlBlock < Liquid::Block
        # Plugin initilializer
        def initialize(tag_name, markup, tokens)
            super
            @markup = markup;
        end

        # Render
        def render(context)
            output = super(context);
            code, pconf, baseurl = PlantUmlEncode64.new(output).encode(), PlantUmlConfig::DEFAULT, Jekyll.configuration({})['baseurl'];
            p = {:url => pconf[:url], :type => pconf[:type], :code => code }
            Jekyll.logger.debug "Generate html with input params  :", p;
            d = RemoteLoader.instance.savedRemoteBinary(p);
            return "<img src=\"%{baseurl}%{uri}\" />" % d.merge({ :baseurl => baseurl });
        end

    end
end

Liquid::Template.register_tag('uml', Jekyll::PlantUmlBlock)
