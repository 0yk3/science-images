<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"/>

  <!--
    Build-time transform: the uncompressed SVG app is copied into index.xml.
    index.xml is what jsDelivr serves as application/xml; browsers render the
    SVG root directly, with no client-side XSLT required.

    This is deliberately build-time only. Chrome 155 removed XSLTProcessor,
    so an XML file with an <?xml-stylesheet?> processing instruction will not
    be transformed in current Chrome.
  -->
  <xsl:template match="/">
    <xsl:comment> Generated from index.svgz by index.xsl. Do not edit by hand. </xsl:comment>
    <xsl:copy-of select="/*"/>
  </xsl:template>
</xsl:stylesheet>
