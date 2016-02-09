# Supply URL of datastructure (go to SDW, choose DB, check its metadata, and copy paste the DSD hyperlink)
get_datastructure <- function(url = "https://sdw-wsrest.ecb.europa.eu/service/datastructure/ESTAT/NA_SEC"){
 
  doc = read_xml(url)
  ns = doc %>>% xml_ns
  
  doc %>>%
    xml_find_all('.//str:DataStructures/str:DataStructure/str:DataStructureComponents/str:DimensionList/str:Dimension', ns = ns) %>>%
    list.map({
      . %>>% xml_attrs %>>%
        as.list %>>%  as.data.table %>>%
        rename(varcode = id) ->
        part1
      
      . %>>%
        xml_find_all('.//str:Enumeration/Ref', ns = ns) %>>% xml_attrs %>>%
        (.[[1L]]) %>>% 
        as.list %>>%  as.data.table %>>%
        rename(codelist = id) ->
        part2
      
      cbind(part1,part2)
    }) %>>% rbindlist(fill = TRUE) %>>%
    select(
      varcode,codelist,version,agencyID,class
    ) ->
    lookup
  
  lookup %>>%
    get_codelists ->
    codelists
  
  lookup[['codelist_name']] <- codelists %>>% list.map(attr(.,'name')) %>>% unlist %>>% as.character
#   data.table(
#     code = codelists %>>% list.map(attr(.,'codelist')) %>>% unlist %>>% as.character,
#     name = codelists %>>% list.map(attr(.,'name')) %>>% unlist %>>% as.character
#   ) ->
#     codelist_names
  
  return(
    list(
      key = lookup,
      codelists = codelists
    )  
  )
}

#get_datastructure() -> lookup
# get_datastructure(url = 'https://sdw-ecb-wsrest.ecb.de/service/datastructure/ECB/ECB_AME1') -> dsd_ameco
# get_datastructure(url = 'https://sdw-ecb-wsrest.ecb.de/service/datastructure/ECB/ECB_SHS6') -> dsd_shs

get_codelists <- function(lookup){
    sprintf("%s/%s/%s/%s",
            "https://sdw-wsrest.ecb.europa.eu/service/codelist",
          ## "https://sdw-ecb-wsrest.ecb.de/service/codelist",
          lookup[['agencyID']],
          lookup[['codelist']],
          lookup[['version']]) ->
    urls
  
  urls %>>%
    list.map({
      doc = read_xml(.)
      ns = doc %>>% xml_ns
      
      doc %>>%
        xml_find_all('.//str:Codelists/str:Codelist', ns = ns) %>>%
        list.map({
          . %>>% xml_attrs %>>%
            as.list %>>% as.data.table ->
            part1
          
          . %>>%
            xml_find_all('./com:Name', ns = ns) %>>%
            xml_text ->
            part2
          
          part2
          
          cbind(part1, name = part2)
        }) %>>%
        rbindlist(fill = TRUE) ->
        meta
      
      doc %>>%
        xml_find_all('.//str:Codelists/str:Codelist', ns = ns) %>>% 
        list.map({
          . %>>%
            xml_find_all('.//str:Code', ns = ns) %>>%
            xml_attrs %>>%
            list.map({
              . %>>% as.list %>>%
                as.data.table
            }) %>>%
            rbindlist(fill = TRUE) ->
            part1
          
          . %>>%
            xml_find_all('.//str:Code/com:Name', ns = ns) %>>%
            xml_text ->
            part2
          
          cbind(part1, name = part2) %>>%
            select(
              id, name
            )
        }) ->
        static
      
      names(static) <- 'dt'
      attr(static[['dt']],'codelist') <- meta[['id']]
      attr(static[['dt']],"name") <- meta[['name']] 
      
      static
    }) ->
    codelists
    
  names(codelists) <- NULL
  
  codelists %>>%
    list.map({
      .[[1L]] ->
        o
      o
     }) ->
    out
    
  names(out) <- out %>>% list.map(attr(.,"codelist")) %>>% unlist %>>% as.character
  
  return(out)
}
  
  
  
  
  