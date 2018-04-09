<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="xs xsi ead xlink"
    version="2.0">
    
    <!-- files analyzed so far:
        print.xsl
        fcaddress.xsl
        dsc.xsl -->
        
        
    <!-- questions:
        
        1) is descgrp required.  see print.xsl, line 416
        if so, what elements do they wrap in descgrp?
        looks like it shouldn't be required, but i haven't confirmed that.
        
        
        2) any need to indicate odd or index elements for "end of file". ASpace
        won't do that, but see print.xsl, line 1091, etc.
            
            we need to keep this question around for now.
            
        
        3) lots of other tests that ASpace-produced EAD will never match, 
        e.g. ead/frontmatter/div.  do any of these sections need to be added
        during the transformation??
        
  ***   4) dao exports are pretty minimal from ASpace.  will need to review those 
        later.  pretty sure we'll need to update the daodesc elements.
        
        
  *     5) ASpace will never provide dsc[@type=analyticover] (see dsc.xsl, line 31)
        Such a thing could be derived during the transformation.
        Is that a requirement?  Would you only do it if there were series?
        
        Yes. use Virginia Wolf papers as an example.
        
             
  *     6) what to do about audience='internal'?  generally i strip these,
        but the example file had <ead audience="internal">, so right now internal-only stuff 
        is carried on over (and i haven't checked to see if the asteria xslt files will respect that attribute)
        
        *** 
        aspace versions 2.x include AT database ids as extra unitids as internal-only in EAD exports.
        if this data was migrated from the AT, we'll probably need to adress this.
        
        Yes.  I'll add that.
        
        

***    7) filenames??? do they matter for Asteria?
            looks like they do based on the site,
            but i wanted to check before addressing it during the transformation stage.
        
        
        YES.  use the EADID.
            oXygen profile file.
        

  
***     8) ASpace "gotchas" like the need to record unordered lists, and the fact that ASpace
        adds "no title" or something for untitled lists. which is bonkers.  
        
        export manosca10.xml from ASpace to check.
        
        
        9)   need to add the "admininfo" descgrp?  
                has access and use restrictions as a subgroup
                prefercite as a subgroup
                acqinfo and processinfo as a subgroup
               
               i don't think this is necessary based on tests so far, 
               but just an FYI.
               
    -->
    
    <!-- 
        See Section 5 for new to-do items:
        
        1. Multple <titleproper>s. If someone adds an extra one (i.e. a filing title)
        then stop the transformtaion (or, just remove it?)

        2. Mutliple <origination> entries. Strip out all but the first, or put the extra ones
        in a control access section?
-->
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8"
        doctype-system="../../dtds/ead.dtd" 
        doctype-public="+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN"/>
    
    <!-- aspace only supports unpublished data, i.e. audience=internal, on components and notes.
        by default, if those are unpublished, we will remove them unless this parameter is changed to something 
        other than false() -->
    <xsl:param name="keep-unpublished-data" select="false()"/>

    
    <!-- Section 1:  just copy what's in the file, removing the namespaces
    and doing anything else to make the result DTD-valid -->
    
    <!-- copy all elements, removing the EAD namespace -->
    <xsl:template match="*">
        <xsl:element name="{local-name()}">
            <xsl:apply-templates select="@* | node()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- remove anything that's internal only. this behavior can be overridden, however -->
    <xsl:template match="*[@audience='internal'][$keep-unpublished-data eq false()]" priority="2"/>
    
    <!-- copy all attributes, removing those XLink namespace
    note: this technique can't be used on every XML transformation since it could create 
    malformed documents (when there are attributes with the same name, but different namespaces),
    but it's fine for what ASpace can produce -->
    <xsl:template match="@*">
        <xsl:attribute name="{local-name()}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- ASpace includes an extptr element for the repository along with an xlink:type attribute.
        @type is not allowed on extptr in the DTD, however, so we remove it here.
    ditto for elements like dao, daogrp, etc.-->
    <xsl:template match="ead:extptr/@xlink:type"/>
    <xsl:template match="ead:dao/@xlink:type"/>
    <xsl:template match="ead:daogrp/@xlink:type"/>
    
    <!-- also need to strip this attribute entirely...
          since we're associating the files with the EAD DTD -->
    <xsl:template match="@xsi:schemaLocation"/>
    
    <!-- copy the rest of the nodes (although  ASpace does not currently produce
     comment or processing-instruction nodes, I'm still keeping them here as that's 
    standard practice when using "identity transformation" templates -->
    <xsl:template match="comment() | text() | processing-instruction()">
        <xsl:copy/>
    </xsl:template>
    
    
    
    <!-- Section 2: update existing data to conform with what's required by the stylesheets, 
        noting which stylesheet enforces that requirement
    some of this could be folded into how we handle attributes, above, 
    but i'm keeping it separate for now for clarity... i hope. -->
    
    <!-- fcaddress.xsl: 
        we've got to lower-case those mainagency codes, as ASpace exports "US", not "us"
        but the stylessheets expect "us-"
     -->
    <xsl:template match="@mainagencycode">
        <xsl:attribute name="mainagencycode">
            <xsl:value-of select="lower-case(.)"/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- 
      dsc:xsl, lines 787, etc. (tests for things like 'folder', but ASpace export might be
    Folder.  doesn't look like this should be required from the one 
    file provided with container elements, but it won't hurt.)
    splitting this out for now, since I'm not sure if we need to do the same or not
    for things like unitdate/@type
    -->
    <xsl:template match="ead:container/@type">
        <xsl:attribute name="type">
            <xsl:value-of select="lower-case(.)"/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- gotta change values like onRequest to onrequest.
        print.xsl, line 1200, etc.-->
    <xsl:template match="@xlink:actuate">
        <xsl:attribute name="actuate">
            <xsl:value-of select="lower-case(.)"/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- remove this template altogether if you don't want to copy over extra
        Agents linked as "creators" -->
    <xsl:template match="ead:archdesc/ead:controlaccess">
        <xsl:element name="{local-name()}">
            <xsl:apply-templates/>
            <xsl:for-each select="ancestor::ead:archdesc/ead:did/ead:origination[position() gt 1]">
                <xsl:apply-templates mode="copied-agents"/>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>
    
    <!-- to get the controlaccess sections right,
        they generally need to have @encodinganalog attributes
        according to the Asteria XSLT
        e.g.
        <xsl:for-each select="*[@encodinganalog='600'] | *[@encodinganalog='610'] | *[@encodinganalog='611'] | *[@encodinganalog='630'] | *[@encodinganalog='650'] | *[@encodinganalog='651'] | *[@encodinganalog='690'] | *[@encodinganalog='691']| *[@encodinganalog='696'] | *[@encodinganalog='697'] | *[@encodinganalog='698'] | *[@encodinganalog='699']">
         ....
         Need a list of when to use the 69x analogs
         -->
    <xsl:template match="ead:controlaccess/ead:*">
        <!-- could add a map, or a sequence to make these transformations, 
            but a choose element should work fine, too, since this shouldn't need to be updated
            and it's easy to decipher what's going on here this way.-->
        <xsl:element name="{local-name()}">
            <xsl:choose>
                <xsl:when test="self::ead:persname or self::ead:famname">
                    <xsl:attribute name="encodinganalog" select="'600'"/>
                </xsl:when>
                <!-- no way to infer meeting name, i don't think,
                    so 611 isn't an option here-->
                <xsl:when test="self::ead:corpname">
                    <xsl:attribute name="encodinganalog" select="'610'"/>
                </xsl:when>
                <xsl:when test="self::ead:title">
                    <xsl:attribute name="encodinganalog" select="'630'"/>
                </xsl:when>
                <xsl:when test="self::ead:subject">
                    <xsl:attribute name="encodinganalog" select="'650'"/>
                </xsl:when>
                <xsl:when test="self::ead:geogname">
                    <xsl:attribute name="encodinganalog" select="'651'"/>
                </xsl:when>
                <xsl:when test="self::ead:genreform">
                    <xsl:attribute name="encodinganalog" select="'655'"/>
                </xsl:when>
                <xsl:when test="self::ead:occupation">
                    <xsl:attribute name="encodinganalog" select="'656'"/>
                </xsl:when>
                <xsl:when test="self::ead:function">
                    <xsl:attribute name="encodinganalog" select="'657'"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="ead:corpname | ead:persname | ead:famname" mode="copied-agents">
        <xsl:element name="{local-name()}">
            <xsl:choose>
                <xsl:when test="self::ead:persname or self::ead:famname">
                    <xsl:attribute name="encodinganalog" select="'600'"/>
                </xsl:when>
                <!-- no way to infer meeting name, i don't think,
                    so 611 isn't an option here-->
                <xsl:when test="self::ead:corpname">
                    <xsl:attribute name="encodinganalog" select="'610'"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- request to add parantheses around container summaries, which are exported as part of the
        second extent element by ASpace.
    we should be safe to just extract text here and not worry about mixed content,
    but just in case some of physdesc statements are hand-endoded in ASpace as physdesc notes
    instead of extent sub-records, i'm attempting to accomodate mixed content here, as well.-->
    <xsl:template match="ead:extent[2][not(starts-with(normalize-space(.), '('))][not(ends-with(normalize-space(.), ')'))]">
        <xsl:element name="extent">
            <xsl:apply-templates select="@*"/>
            <xsl:text>(</xsl:text>
                <xsl:apply-templates/>
            <xsl:text>)</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <!-- time to construct the analytic overview DSC section,
        using mode and the Virginia Woolf collection as an example for the desired output-->
    
    
    
    <!-- Section 3: make it work regardless of c elments of cN elements -->
    <xsl:template match="ead:c">
        <xsl:param name="c-level" as="xs:integer" select="1"/>
        <xsl:variable name="component-name" as="xs:string">
            <xsl:value-of select="concat('c', xs:string(format-number($c-level, '00')))"/>
        </xsl:variable>
        <xsl:if test="$c-level eq 13">
            <xsl:message terminate="yes">EAD doesn't like the number 13 and refuses to count that high (additionally, a c12 element cannot conceive a 'c' for a child).  Therefore, this EAD document would no longer be valid if all of its highly-nested  'c' elements were enumerated. To uphold validity, as well as the original integretity of this document, this transformation has thus been terminated.</xsl:message>
        </xsl:if>
        <xsl:element name="{$component-name}">
            <xsl:apply-templates select="@*|node()">
                <xsl:with-param name="c-level" as="xs:integer" select="$c-level + 1"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>
    
    <!-- Section 4:  Horrible hacks to address invalid EAD serializations provided by ArchivesSpace -->
    
    <!-- got a character entity in a note?  ASpace won't wrap paragraph tags during export, resulting in invalid data.
        Example (see Gordon&amp;Lousie... which is perfectly fine, but it causes ASpace many problems):
            <accessrestrict id="aspace_f1984b421add73350a1c2aeafbe15514">
      <head>Conditions Governing Access</head> Keep closed until all permission forms have been
      returned. Restrictions as of 10/29/15: Timony: Video available on campus only; close for 50
      years following portions of transcript/video: .52-1:44; 19:54-20:50; 52:50-53.44. Nina
      Gordon&amp;Louise Post (Veruca Salt): Close following portions of tanscript/video for 25
      years: 46:45-47:10 (L7); 1:46:38-1:54:28 (Louise) </accessrestrict>
    
    to fix this bug, we'll look for "text" nodes that are siblings of head elements.
    find something like that, then wrap it in a "p" tag and hope for the best.
    i need more examples of when this can happen, though, to really fix the issue...
    but here's the first attempt.
    -->
    
    <xsl:template match="text()[normalize-space()][preceding-sibling::ead:head][1]">
        <xsl:element name="p">
            <xsl:copy-of select="."/>
        </xsl:element>
    </xsl:template>
    
    
    <!-- this is based on the fact that ASpace will export @id attributes on 
    notes (such as the langmaterial note), but that it won't output an @id
    attribute on the language code data element.-->
    <xsl:template match="ead:archdesc/ead:did/ead:langmaterial[@id]">
        <xsl:element name="langmaterial">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="ead:langmaterial[not(@id)][../ead:langmaterial/@id]"/>
    <xsl:template match="ead:archdesc/ead:did/ead:langmaterial[not(@id)][not(../ead:langmaterial/@id)]">
        <xsl:element name="langmaterial">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!-- hack to remove the duplicate elements exported by ArchivesSpace for creator + subject
            should no longer be necessary in versions 2.x of ASpace
            but since some bugs have a habit of coming back to life, it might not be a bad idea to keep this around.
    e.g.
        <controlaccess>
          <persname authfilenumber="no2014138850" role="fmo" source="naf">Arthur, Kat</persname>
          <persname authfilenumber="no2014138850" source="naf">Arthur, Kat</persname>
        </controlaccess>
        
   this might not still be required; if not, just delete line 340
    -->
    <xsl:template match="ead:controlaccess/*[. = preceding-sibling::*]" priority="2"/>
    
    <!-- oh, digital object exports from ASpace.
        to keep things somewhat simple, let's just remove the daodesc
    since it repeats the same text that's added to the dao title attribute-->
    <xsl:template match="ead:daodesc"/>
    
    <xsl:template match="ead:dao/@xlink:title[not(starts-with(., 'Link to'))]">
        <xsl:attribute name="title">
            <xsl:value-of select="concat('Link to ', .)"/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- what else, ASpace?  
        e.g. if Smith has table elements, we may need to add a
        few other things here, as well 
      -->
    
    <!-- Section 5:  new to-do items -->
    <xsl:template match="ead:titleproper[2]">
        <xsl:message terminate="yes">A filing title was added in ArchivesSpace. Please fix the Resource record and try again.</xsl:message>
    </xsl:template>
    
    <xsl:template match="ead:archdesc/ead:did/ead:origination[position() gt 1]">
        <xsl:message terminate="no">More than one Agent as creator has been added in ArchivesSpace. The first creator will remain as is, but 
        the others will be moved to the controlaccess section, as long as the Resource record 
        has additional subjects and/or agents linked.</xsl:message>
    </xsl:template>
    
     
</xsl:stylesheet>