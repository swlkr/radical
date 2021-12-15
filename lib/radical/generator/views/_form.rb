<<~ERB
  <%== form model: #{singular} do |f| %>
    #{inputs(leading: 4)}
    <%== f.submit 'Save' %>
  <% end %>
ERB
