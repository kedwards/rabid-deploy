<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ocrsp="urn:ocr-response"
                xmlns:ocstat="urn:ocr-status"
                xmlns:methstat="urn:or-methodStatus">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no" standalone="yes"/>

  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="ocrsp:response">
        <xsl:element name="ConnexResponseWrapper">
          <Response xsi:type="ConnexErrorResponse" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <xsl:copy>
              <xsl:apply-templates select="node() | @*" mode="connexStandardWrapper" />
            </xsl:copy>
          </Response>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="node() | @*"  />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="node() | @*" mode="connexStandardWrapper">
    <xsl:apply-templates select="node() | @*" mode="connexStandardWrapper"/>
  </xsl:template>

  <xsl:template match="node() | @*" >
    <xsl:copy>
      <xsl:apply-templates select="node() | @*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ocstat:status" mode="connexStandardWrapper" >
    <xsl:element name="ErrorMessages" >
      <xsl:attribute name="ErrorCode" >
        <xsl:value-of  select="ocstat:errorCode"/>
      </xsl:attribute>
      <xsl:attribute name="ErrorMessage" >
        <xsl:value-of  select="ocstat:errorMsg"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template match="methstat:status" mode="connexStandardWrapper" >
    <xsl:element name="ErrorMessages" >
      <xsl:attribute name="ErrorCode" >
        <xsl:value-of  select="methstat:errorCode"/>
      </xsl:attribute>
      <xsl:attribute name="ErrorMessage" >
        <xsl:value-of  select="methstat:errorMsg"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
