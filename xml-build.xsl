<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"/>
  <xsl:param name="target" select="'xml'"/>

  <!--
    Build-time transform for every .svgz route.

    The uncompressed SVG app is copied to the matching .xml, .svg, .xhtml, or
    .xsl file, and every "svgz" reference (links, entry name, navigation regex)
    is rewritten to the requested target extension. Select the target by
    passing the "target" parameter, for example: target=svg

    The default is "xml". The .xml and .svg variants are served as
    application/xml and image/svg+xml by jsDelivr and statically.io. The .xhtml
    variant is served as application/xhtml+xml by jsDelivr. The .xsl variant is
    only an alternate extension served as application/xml by jsDelivr; it is
    not an XSLT stylesheet.

    This is deliberately build-time only. Chrome 155 removed XSLTProcessor,
    so an XML file with an <?xml-stylesheet?> processing instruction will not
    be transformed in current Chrome.

    Every generated route shows a blank screen for five seconds before the
    app is revealed. The overlay is also present in the .svgz sources; it is
    only added here when a source does not already carry it, so the transform
    stays idempotent.
  -->
  <xsl:template match="/">
    <xsl:comment> Generated from the matching compressed SVG source by xml-build.xsl. Do not edit by hand. </xsl:comment>
    <xsl:apply-templates select="/*"/>
  </xsl:template>

  <xsl:template match="/*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:if test="not(*[@id='blank-screen'])">
        <rect xmlns="http://www.w3.org/2000/svg" id="blank-screen" x="0" y="0" width="100%" height="100%" fill="#ffffff"/>
        <script xmlns="http://www.w3.org/2000/svg"><![CDATA[
(function () {
  var blank = document.getElementById("blank-screen");
  if (!blank) return;
  setTimeout(function () {
    if (blank.parentNode) blank.parentNode.removeChild(blank);
  }, 5000);
})();
        ]]></script>
      </xsl:if>
    </xsl:copy>
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
        <xsl:value-of select="$target"/>
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
