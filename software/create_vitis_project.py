import vitis
client = vitis.create_client()
print("--- Setting Workspace ---")
client.set_workspace("C:/Users/akash/mnist_cnn_workspace_v2")
print("--- Creating Platform Component ---")
client.create_platform_component(name="soc_platform", hw_design="C:/temp/soc_design_wrapper.xsa", os="standalone", cpu="microblaze_0")
print("--- Creating Application Component ---")
client.create_app_component(name="mnist_cnn_app", platform="soc_platform", domain="standalone_microblaze_0", template="empty_application")
print("--- Vitis Project Created Successfully! ---")
