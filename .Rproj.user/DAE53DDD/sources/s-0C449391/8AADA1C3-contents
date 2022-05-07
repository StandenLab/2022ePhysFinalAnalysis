theme_JEB <- function(){ 
  font = "Arial"  #assign font family up front
  
  theme_bw() %+replace%    #replace elements we want to change
    
    theme(
      
      #grid elements
      panel.grid.major = element_blank(),    #strip major gridlines
      panel.grid.minor = element_blank(),    #strip minor gridlines
      panel.border = element_blank(),
      panel.background = element_rect(fill="transparent"),

      
      #since theme_minimal() already strips axis lines, 
      #we don't need to do that again
      
      #text elements
      plot.title = element_blank(),               #raise slightly
      
      plot.subtitle = element_blank(),               #font size
      
      plot.caption = element_blank(),               #right align
      
      axis.title = element_text(
        family = font,
        size = 8),               #font size
      
      axis.text = element_text(              #axis text
        family = font,            #axis famuly
        size = 8),                #font size)

      legend.text = element_text(              #axis text
        family = font,            #axis famuly
        size = 8),
            
      legend.title = element_text(              #axis text
        family = font,            #axis famuly
        size = 8)
    )
}