<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"/>

  <!--
    Build-time transform for every .svgz route.

    The uncompressed SVG app is copied to the matching .xml file, and every
    "svgz" reference (links, entry name, navigation regex) is rewritten to
    "xml". The resulting XML is served by jsDelivr as application/xml and
    renders directly in Chrome.

    This is deliberately build-time only. Chrome 155 removed XSLTProcessor,
    so an XML file with an <?xml-stylesheet?> processing instruction will not
    be transformed in current Chrome.
  -->
  <xsl:template match="/">
    <xsl:comment> Generated from the matching compressed SVG source by xml-build.xsl. Do not edit by hand. </xsl:comment>
    <xsl:apply-templates select="/*"/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:choose>
      <xsl:when test="contains(., 'svgz')">
        <xsl:attribute name="{name()}">
          <xsl:call-template name="replace-svgz">
            <xsl:with-param name="text" select="."/>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:call-template name="replace-svgz">
      <xsl:with-param name="text" select="."/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="comment()|processing-instruction()">
    <xsl:copy/>
  </xsl:template>

  <xsl:template name="replace-svgz">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="contains($text, 'svgz')">
        <xsl:value-of select="substring-before($text, 'svgz')"/>
        <xsl:text>xml</xsl:text>
        <xsl:call-template name="replace-svgz">
          <xsl:with-param name="text" select="substring-after($text, 'svgz')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
