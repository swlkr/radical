<<~ERB
  <%== form model: #{singular} do |f| %>
    #{inputs(leading: 4)}
    <%== f.button 'Save' %>
  <% end %>
ERB
